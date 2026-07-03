import Foundation

/// Builds a random connected, planar (crossing-free) mizori network, derives
/// the island numbers from it, then verifies with the solver that the puzzle
/// is uniquely + deductively solvable. Fully deterministic from a seed.
struct HashiGenerator {

    struct GenResult {
        let puzzle: HashiPuzzle
        let difficulty: HashiDifficulty
        let topTier: Int
    }

    let size: HashiGridSize
    let target: HashiDifficulty

    // Tunables derived from grid + difficulty.
    private var targetIslands: Int
    private var maxDist: Int
    private var doubleProb: Double
    private var extraEdgeProb: Double
    private var upgradeProb: Double

    init(size: HashiGridSize, target: HashiDifficulty) {
        self.size = size
        self.target = target

        let cells = size.width * size.height
        // Island density roughly scales with area.
        var base = Int(Double(cells) * 0.22)
        switch target {
        case .easy: base = Int(Double(cells) * 0.18)
        case .medium: base = Int(Double(cells) * 0.20)
        case .hard: base = Int(Double(cells) * 0.23)
        case .expert: base = Int(Double(cells) * 0.25)
        }
        self.targetIslands = max(6, base)
        self.maxDist = max(2, min(size.width, size.height) - 2)

        switch target {
        case .easy:   doubleProb = 0.28; extraEdgeProb = 0.06; upgradeProb = 0.05
        case .medium: doubleProb = 0.36; extraEdgeProb = 0.16; upgradeProb = 0.12
        case .hard:   doubleProb = 0.44; extraEdgeProb = 0.34; upgradeProb = 0.24
        case .expert: doubleProb = 0.54; extraEdgeProb = 0.58; upgradeProb = 0.40
        }
    }

    // MARK: Public entry

    /// Generate a unique, deducible puzzle for the given seed. Retries with
    /// derived sub-seeds, preferring the target difficulty but always returning
    /// a unique + deducible puzzle.
    func generate(seed: UInt64, maxAttempts: Int = 500) -> GenResult {
        var fallback: GenResult? = nil
        for attempt in 0..<maxAttempts {
            var rng = HashiRandom(seed: mixSeed([seed, UInt64(attempt), 0x5151]))
            guard let puzzle = buildNetwork(rng: &rng) else { continue }
            let solver = HashiSolver(HashiBoardGraph(puzzle))
            let d = solver.deduce()
            guard d.solved && !d.contradiction else { continue }
            // Fully deduced ⇒ unique (only one degree+crossing-consistent layout).
            let diff = HashiSolver.classify(steps: d.steps)
            let result = GenResult(puzzle: puzzle, difficulty: diff, topTier: d.topTier)
            if diff == target {
                return result
            }
            // Keep the closest-tier unique puzzle as a fallback.
            if fallback == nil ||
                abs(diff.rawValue - target.rawValue) < abs(fallback!.difficulty.rawValue - target.rawValue) {
                fallback = result
            }
        }
        if let fb = fallback { return fb }
        // Extremely unlikely: degrade to a trivially-unique tiny puzzle.
        return trivialFallback(seed: seed)
    }

    // MARK: Network construction

    private func buildNetwork(rng: inout HashiRandom) -> HashiPuzzle? {
        let w = size.width
        let h = size.height
        // occupancy: 0 empty, 1 island, 2 h-mizori, 3 v-mizori
        var occ = Array(repeating: 0, count: w * h)
        var islandCells = [Int]()              // ordered list of island cell ids
        var degree = [Int: Int]()              // cell -> degree
        var mizoris = [String: Int]()          // "min-max" cellpair -> count

        func key(_ a: Int, _ b: Int) -> String { a < b ? "\(a)-\(b)" : "\(b)-\(a)" }

        // Seed island near centre-ish random cell.
        let startR = rng.int(in: 1...(h - 2 < 1 ? h - 1 : h - 2))
        let startC = rng.int(in: 1...(w - 2 < 1 ? w - 1 : w - 2))
        let start = startR * w + startC
        occ[start] = 1
        islandCells.append(start)
        degree[start] = 0

        let dirs = [(-1, 0), (1, 0), (0, -1), (0, 1)]

        var growthGuard = 0
        let maxGrowth = targetIslands * 60
        while islandCells.count < targetIslands && growthGuard < maxGrowth {
            growthGuard += 1
            let p = islandCells[rng.int(islandCells.count)]
            let pr = p / w, pc = p % w
            let (dr, dc) = dirs[rng.int(4)]
            let dist = rng.int(in: 1...maxDist)

            let nr = pr + dr * dist
            let nc = pc + dc * dist
            if nr < 0 || nr >= h || nc < 0 || nc >= w { continue }
            let nCell = nr * w + nc
            if occ[nCell] != 0 { continue }

            // All intermediate cells must be empty (no crossing / pass-through).
            var ok = true
            var inter = [Int]()
            for step in 1..<dist {
                let cr = pr + dr * step
                let cc = pc + dc * step
                let cell = cr * w + cc
                if occ[cell] != 0 { ok = false; break }
                inter.append(cell)
            }
            if !ok { continue }
            if (degree[p] ?? 0) >= 7 { continue }

            // Decide single or double.
            let dbl = rng.chance(doubleProb) && (degree[p] ?? 0) <= 6
            let count = dbl ? 2 : 1

            // Place.
            occ[nCell] = 1
            islandCells.append(nCell)
            degree[nCell] = count
            degree[p, default: 0] += count
            let mark = (dr != 0) ? 3 : 2
            for cell in inter { occ[cell] = mark }
            mizoris[key(p, nCell)] = count
        }

        if islandCells.count < 4 { return nil }

        // Extra edges (cycles) + double upgrades to enrich constraints.
        addExtraEdges(rng: &rng, w: w, h: h, occ: &occ,
                      islandCells: islandCells, degree: &degree, mizoris: &mizoris)

        // Build clues from degrees.
        var clues = [HashiClue]()
        for cell in islandCells {
            let d = degree[cell] ?? 0
            if d < 1 || d > 8 { return nil }
            clues.append(HashiClue(r: cell / w, c: cell % w, need: d))
        }
        // Stable order: by row then column (nice for rendering).
        clues.sort { $0.r != $1.r ? $0.r < $1.r : $0.c < $1.c }
        return HashiPuzzle(width: w, height: h, clues: clues)
    }

    private func addExtraEdges(rng: inout HashiRandom, w: Int, h: Int,
                               occ: inout [Int], islandCells: [Int],
                               degree: inout [Int: Int], mizoris: inout [String: Int]) {
        func key(_ a: Int, _ b: Int) -> String { a < b ? "\(a)-\(b)" : "\(b)-\(a)" }
        let isIsland = Set(islandCells)

        // Find consecutive collinear island pairs with clear intermediate cells.
        // Horizontal.
        var candidates = [(Int, Int, [Int], Int)]()   // a, b, inter, mark
        for r in 0..<h {
            var prev = -1
            for c in 0..<w {
                let cell = r * w + c
                if isIsland.contains(cell) {
                    if prev >= 0 {
                        let pc = prev % w
                        var inter = [Int]()
                        var clear = true
                        if c - pc > 1 {
                            for cc in (pc + 1)..<c {
                                let ic = r * w + cc
                                if occ[ic] != 0 { clear = false; break }
                                inter.append(ic)
                            }
                        }
                        if clear { candidates.append((prev, cell, inter, 2)) }
                    }
                    prev = cell
                }
            }
        }
        // Vertical.
        for c in 0..<w {
            var prev = -1
            for r in 0..<h {
                let cell = r * w + c
                if isIsland.contains(cell) {
                    if prev >= 0 {
                        let pr = prev / w
                        var inter = [Int]()
                        var clear = true
                        if r - pr > 1 {
                            for rr in (pr + 1)..<r {
                                let ic = rr * w + c
                                if occ[ic] != 0 { clear = false; break }
                                inter.append(ic)
                            }
                        }
                        if clear { candidates.append((prev, cell, inter, 3)) }
                    }
                    prev = cell
                }
            }
        }

        candidates = rng.shuffled(candidates)
        for (a, b, inter, mark) in candidates {
            if mizoris[key(a, b)] != nil { continue }
            if !rng.chance(extraEdgeProb) { continue }
            if (degree[a] ?? 0) >= 8 || (degree[b] ?? 0) >= 8 { continue }
            // Re-check clear (a previous extra edge may have filled cells).
            var clear = true
            for ic in inter where occ[ic] != 0 { clear = false; break }
            if !clear { continue }
            let dbl = rng.chance(doubleProb) && (degree[a] ?? 0) <= 6 && (degree[b] ?? 0) <= 6
            let count = dbl ? 2 : 1
            if (degree[a] ?? 0) + count > 8 || (degree[b] ?? 0) + count > 8 { continue }
            for ic in inter { occ[ic] = mark }
            mizoris[key(a, b)] = count
            degree[a, default: 0] += count
            degree[b, default: 0] += count
        }

        // Upgrade some single mizoris to doubles.
        for (k, v) in mizoris where v == 1 {
            let parts = k.split(separator: "-").compactMap { Int($0) }
            guard parts.count == 2 else { continue }
            let a = parts[0], b = parts[1]
            if (degree[a] ?? 0) >= 8 || (degree[b] ?? 0) >= 8 { continue }
            if rng.chance(upgradeProb) {
                mizoris[k] = 2
                degree[a, default: 0] += 1
                degree[b, default: 0] += 1
            }
        }
    }

    private func trivialFallback(seed: UInt64) -> GenResult {
        // A guaranteed-unique 2-island puzzle (a single forced mizori).
        let w = size.width, h = size.height
        let clues = [HashiClue(r: 0, c: 0, need: 1), HashiClue(r: 0, c: 1, need: 1)]
        return GenResult(puzzle: HashiPuzzle(width: w, height: h, clues: clues),
                         difficulty: .easy, topTier: 0)
    }
}
