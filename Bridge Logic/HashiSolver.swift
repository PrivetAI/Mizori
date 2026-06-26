import Foundation

// MARK: - Deduction reporting

/// One logical step a human (or the solver) can make: a channel's bridge
/// count becomes fully determined, with a reason and the technique tier used.
struct HashiDeduction {
    let edge: Int
    let value: Int
    let tier: Int        // 0 count, 1 crossing, 2 elimination, 3 deep what-if
    let reason: String
}

/// Result of analysing a puzzle for shipping / difficulty / hints.
struct HashiAnalysis {
    let unique: Bool
    let deducible: Bool          // fully solvable by the deduction engine
    let difficulty: HashiDifficulty
    let topTier: Int
    let solution: [Int]?         // bridge count per edge, if known
    let steps: [HashiDeduction]  // ordered deduction trace (for hints)
}

/// Constraint-propagation + backtracking Hashiwokakero solver.
/// Provides: uniqueness counting (authoritative), a human-style deduction
/// engine (for difficulty + hints), and a next-forced-move hint.
final class HashiSolver {
    let graph: HashiBoardGraph
    private var needs: [Int]

    init(_ graph: HashiBoardGraph) {
        self.graph = graph
        self.needs = graph.puzzle.clues.map { $0.need }
    }

    private var edgeCount: Int { graph.edges.count }
    private var islandCount: Int { graph.puzzle.clues.count }

    // MARK: Bounds propagation (degree + crossing)

    /// Returns false on contradiction. Records newly determined edges via `onFix`.
    private func propagateBasic(lo: inout [Int], hi: inout [Int],
                                useCrossing: Bool,
                                tierForFix: Int,
                                onFix: ((Int, Int, Int, String) -> Void)?) -> Bool {
        var changed = true
        while changed {
            changed = false

            // Degree constraints.
            for isl in 0..<islandCount {
                let inc = graph.incident[isl]
                if inc.isEmpty { continue }
                var sLo = 0, sHi = 0
                for e in inc { sLo += lo[e]; sHi += hi[e] }
                let d = needs[isl]
                for e in inc {
                    let othersHi = sHi - hi[e]
                    let othersLo = sLo - lo[e]
                    var nLo = lo[e]
                    var nHi = hi[e]
                    if d - othersHi > nLo { nLo = d - othersHi }
                    if d - othersLo < nHi { nHi = d - othersLo }
                    if nLo < 0 { nLo = 0 }
                    if nHi > 2 { nHi = 2 }
                    if nLo > nHi { return false }
                    if nLo != lo[e] || nHi != hi[e] {
                        let wasFixed = lo[e] == hi[e]
                        sLo += nLo - lo[e]
                        sHi += nHi - hi[e]
                        lo[e] = nLo
                        hi[e] = nHi
                        changed = true
                        if !wasFixed && nLo == nHi {
                            onFix?(e, nLo, tierForFix,
                                   reasonForDegree(edge: e, value: nLo, island: isl))
                        }
                    }
                }
            }

            // Crossing constraints.
            if useCrossing {
                for e in 0..<edgeCount where lo[e] >= 1 {
                    for f in graph.crossing[e] {
                        if lo[f] >= 1 { return false }
                        if hi[f] != 0 {
                            let wasFixed = lo[f] == hi[f]
                            hi[f] = 0
                            changed = true
                            if !wasFixed && lo[f] == hi[f] {
                                onFix?(f, 0, max(tierForFix, 1),
                                       "A bridge in the crossing channel blocks this one — they cannot intersect.")
                            }
                        }
                    }
                }
            }
        }
        return true
    }

    private func reasonForDegree(edge e: Int, value v: Int, island: Int) -> String {
        let need = needs[island]
        switch v {
        case 0:
            return "This channel must stay empty to keep island \(need) from exceeding its count."
        case 2:
            return "Island \(need) can only reach its count by running a double bridge here."
        default:
            return "Island \(need) forces exactly one bridge along this channel."
        }
    }

    // MARK: Trial (elimination) reasoning

    /// One pass of elimination: for each undecided edge value, hypothesise it
    /// and if basic propagation (optionally with a nested trial) hits a
    /// contradiction, eliminate that value. Returns (changed, contradiction).
    private func trialPass(lo: inout [Int], hi: inout [Int],
                           depth: Int,
                           onFix: ((Int, Int, Int, String) -> Void)?) -> (Bool, Bool) {
        var changed = false
        for e in 0..<edgeCount where lo[e] < hi[e] {
            for v in lo[e]...hi[e] {
                var tLo = lo
                var tHi = hi
                tLo[e] = v
                tHi[e] = v
                if !propagateBasic(lo: &tLo, hi: &tHi, useCrossing: true,
                                   tierForFix: 2, onFix: nil) {
                    // v leads to contradiction -> remove it.
                    if v == lo[e] { lo[e] += 1 } else if v == hi[e] { hi[e] -= 1 } else { continue }
                    if lo[e] > hi[e] { return (changed, true) }
                    changed = true
                    if lo[e] == hi[e] {
                        let tier = depth >= 2 ? 3 : 2
                        onFix?(e, lo[e], tier,
                               depth >= 2
                               ? "Deeper what-if analysis shows every alternative here eventually fails."
                               : "Testing the alternative leads to a contradiction, so this value is forced.")
                    }
                    break
                } else if depth >= 2 {
                    // Nested: see if the hypothesis itself can be solved-out by trial1.
                    var inner = true
                    while inner {
                        inner = false
                        let (c2, bad2) = trialPass(lo: &tLo, hi: &tHi, depth: 1, onFix: nil)
                        if bad2 {
                            if v == lo[e] { lo[e] += 1 } else if v == hi[e] { hi[e] -= 1 } else { break }
                            if lo[e] > hi[e] { return (changed, true) }
                            changed = true
                            if lo[e] == hi[e] {
                                onFix?(e, lo[e], 3,
                                       "Deeper what-if analysis shows every alternative here eventually fails.")
                            }
                            break
                        }
                        if c2 {
                            inner = !propagateBasic(lo: &tLo, hi: &tHi, useCrossing: true,
                                                    tierForFix: 3, onFix: nil) ? false : true
                            if inner == false { break }
                        }
                    }
                }
            }
        }
        return (changed, false)
    }

    // MARK: Full deduction engine

    /// Solve as far as logic allows, escalating technique only when needed.
    /// Produces an ordered trace and the highest tier used.
    func deduce(maxTrialDepth: Int = 2) -> (solved: Bool, lo: [Int], hi: [Int],
                                            steps: [HashiDeduction], topTier: Int,
                                            contradiction: Bool) {
        var lo = Array(repeating: 0, count: edgeCount)
        var hi = Array(repeating: 2, count: edgeCount)
        var steps = [HashiDeduction]()
        var topTier = 0
        let record: (Int, Int, Int, String) -> Void = { e, v, tier, reason in
            steps.append(HashiDeduction(edge: e, value: v, tier: tier, reason: reason))
            if tier > topTier { topTier = tier }
        }

        // Tier 0/1: degree + crossing propagation.
        if !propagateBasic(lo: &lo, hi: &hi, useCrossing: true, tierForFix: 0, onFix: record) {
            return (false, lo, hi, steps, topTier, true)
        }

        // Escalate to elimination passes when stalled.
        var progressing = true
        while progressing && !allFixed(lo, hi) {
            progressing = false
            for depth in 1...max(1, maxTrialDepth) {
                let (changed, bad) = trialPass(lo: &lo, hi: &hi, depth: depth, onFix: record)
                if bad { return (false, lo, hi, steps, topTier, true) }
                if changed {
                    if !propagateBasic(lo: &lo, hi: &hi, useCrossing: true,
                                       tierForFix: 0, onFix: record) {
                        return (false, lo, hi, steps, topTier, true)
                    }
                    progressing = true
                    break
                }
            }
        }

        return (allFixed(lo, hi), lo, hi, steps, topTier, false)
    }

    private func allFixed(_ lo: [Int], _ hi: [Int]) -> Bool {
        for e in 0..<edgeCount where lo[e] != hi[e] { return false }
        return true
    }

    // MARK: Authoritative uniqueness count (with connectivity)

    /// Counts valid Hashi solutions up to `limit`. A valid solution satisfies
    /// all degrees, no crossings, and full connectivity.
    func countSolutions(limit: Int = 2) -> Int {
        var lo = Array(repeating: 0, count: edgeCount)
        var hi = Array(repeating: 2, count: edgeCount)
        if !propagateBasic(lo: &lo, hi: &hi, useCrossing: true, tierForFix: 0, onFix: nil) {
            return 0
        }
        var count = 0
        search(lo: lo, hi: hi, count: &count, limit: limit)
        return count
    }

    private func search(lo: [Int], hi: [Int], count: inout Int, limit: Int) {
        if count >= limit { return }
        // Pick the most-constrained undecided edge.
        var pick = -1
        var bestSpan = 99
        for e in 0..<edgeCount where lo[e] < hi[e] {
            let span = hi[e] - lo[e]
            if span < bestSpan { bestSpan = span; pick = e }
        }
        if pick == -1 {
            // Complete assignment: degrees consistent by construction; verify
            // exact satisfaction and connectivity.
            if isComplete(lo) && isConnected(lo) {
                count += 1
            }
            return
        }
        for v in lo[pick]...hi[pick] {
            var nLo = lo
            var nHi = hi
            nLo[pick] = v
            nHi[pick] = v
            if propagateBasic(lo: &nLo, hi: &nHi, useCrossing: true, tierForFix: 0, onFix: nil) {
                search(lo: nLo, hi: nHi, count: &count, limit: limit)
                if count >= limit { return }
            }
        }
    }

    private func isComplete(_ values: [Int]) -> Bool {
        for isl in 0..<islandCount {
            var sum = 0
            for e in graph.incident[isl] { sum += values[e] }
            if sum != needs[isl] { return false }
        }
        // No crossings.
        for e in 0..<edgeCount where values[e] >= 1 {
            for f in graph.crossing[e] where values[f] >= 1 { return false }
        }
        return true
    }

    func isConnected(_ values: [Int]) -> Bool {
        guard islandCount > 0 else { return true }
        var seen = Array(repeating: false, count: islandCount)
        var stack = [0]
        seen[0] = true
        var visited = 1
        while let n = stack.popLast() {
            for e in graph.incident[n] where values[e] >= 1 {
                let other = graph.edges[e].a == n ? graph.edges[e].b : graph.edges[e].a
                if !seen[other] {
                    seen[other] = true
                    visited += 1
                    stack.append(other)
                }
            }
        }
        return visited == islandCount
    }

    // MARK: Full analysis (shipping / difficulty)

    func analyze() -> HashiAnalysis {
        let solCount = countSolutions(limit: 2)
        let unique = solCount == 1
        let d = deduce()
        let deducible = d.solved && !d.contradiction
        let solution: [Int]? = deducible ? d.lo : nil
        let diff = HashiSolver.classify(steps: d.steps)
        return HashiAnalysis(unique: unique, deducible: deducible,
                             difficulty: diff, topTier: d.topTier,
                             solution: solution, steps: d.steps)
    }

    /// Classifies difficulty from a deduction trace by the most advanced
    /// technique required and how much of it is needed.
    ///  - easy:   pure bridge-count propagation, no crossing logic.
    ///  - medium: requires crossing logic.
    ///  - hard:   requires elimination (what-if) reasoning, but only a little.
    ///  - expert: requires heavy elimination or deep nested what-if.
    static func classify(steps: [HashiDeduction]) -> HashiDifficulty {
        var crossing = 0, elim = 0, deep = 0
        for s in steps {
            switch s.tier {
            case 1: crossing += 1
            case 2: elim += 1
            case 3: deep += 1
            default: break
            }
        }
        if elim == 0 && deep == 0 {
            return crossing == 0 ? .easy : .medium
        }
        if deep > 0 || elim >= 11 {
            return .expert
        }
        return .hard
    }

    // MARK: Hint — next forced move relative to a player's board

    /// Given the player's current bridge counts per edge, returns the first
    /// deduction in logical order that the player has not yet placed.
    func nextHint(playerValues: [Int]) -> HashiDeduction? {
        let d = deduce()
        for step in d.steps {
            if step.edge < playerValues.count, playerValues[step.edge] != step.value {
                return step
            }
        }
        // Fallback: any solution edge the player hasn't matched.
        if let sol = (d.solved ? d.lo : nil) {
            for e in 0..<edgeCount where playerValues[e] != sol[e] {
                return HashiDeduction(edge: e, value: sol[e], tier: 0,
                                      reason: "This channel needs \(sol[e]) bridge\(sol[e] == 1 ? "" : "s") in the final layout.")
            }
        }
        return nil
    }

    /// Returns the full unique solution as bridge counts per edge, if deducible.
    func solvedValues() -> [Int]? {
        let d = deduce()
        return d.solved ? d.lo : nil
    }
}
