import Foundation

// MARK: - Difficulty tiers

enum HashiDifficulty: Int, CaseIterable, Codable {
    case easy = 0
    case medium = 1
    case hard = 2
    case expert = 3

    var title: String {
        switch self {
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .expert: return "Expert"
        }
    }

    var blurb: String {
        switch self {
        case .easy: return "Gentle warm-ups solved with simple counting."
        case .medium: return "Adds crossing logic between channels."
        case .hard: return "Requires elimination chains to crack."
        case .expert: return "Deep what-if reasoning for seasoned navigators."
        }
    }
}

// MARK: - Grid sizes

struct HashiGridSize: Codable, Equatable {
    let width: Int
    let height: Int

    var label: String { "\(width)×\(height)" }

    static let s7 = HashiGridSize(width: 7, height: 7)
    static let s9 = HashiGridSize(width: 9, height: 9)
    static let s11 = HashiGridSize(width: 11, height: 11)
    static let s13 = HashiGridSize(width: 13, height: 13)
    static let s17 = HashiGridSize(width: 17, height: 17)

    static let all: [HashiGridSize] = [s7, s9, s11, s13, s17]
}

// MARK: - Puzzle definition

/// An island as specified in a puzzle (position + required mizori count).
struct HashiClue: Codable, Equatable {
    let r: Int
    let c: Int
    let need: Int
}

/// A puzzle: a grid with island clues. The solution is derivable (and unique)
/// but is not part of the shipped definition — it is recomputed by the solver.
struct HashiPuzzle: Codable, Equatable {
    let width: Int
    let height: Int
    let clues: [HashiClue]

    func clueIndex(forCell cell: Int) -> Int? {
        for (i, cl) in clues.enumerated() where cl.r * width + cl.c == cell {
            return i
        }
        return nil
    }
}

// MARK: - Edges (candidate mizori channels)

/// A candidate mizori between two collinear, consecutive islands with no
/// island and nothing geometrically between them. Carries 0, 1 or 2 mizoris.
struct HashiEdge {
    let a: Int            // index into clues
    let b: Int            // index into clues
    let horizontal: Bool
    let cells: [Int]      // intermediate cell indices (r*width+c)
}

/// Pre-computed, immutable structure describing a puzzle's graph: edges,
/// per-island incidence, and which edges cross each other.
struct HashiBoardGraph {
    let puzzle: HashiPuzzle
    let edges: [HashiEdge]
    let incident: [[Int]]     // island index -> incident edge indices
    let crossing: [[Int]]     // edge index -> edge indices it crosses

    init(_ puzzle: HashiPuzzle) {
        self.puzzle = puzzle
        let w = puzzle.width
        let h = puzzle.height
        let clues = puzzle.clues

        // Map cell -> clue index for occupancy lookups.
        var islandAt = [Int: Int]()
        for (i, cl) in clues.enumerated() {
            islandAt[cl.r * w + cl.c] = i
        }

        var edges = [HashiEdge]()

        // Horizontal edges: scan each row left to right for consecutive islands.
        for r in 0..<h {
            var prev: Int? = nil
            for c in 0..<w {
                if let isl = islandAt[r * w + c] {
                    if let p = prev {
                        let pc = clues[p].c
                        var cells = [Int]()
                        if c - pc > 1 {
                            for cc in (pc + 1)..<c { cells.append(r * w + cc) }
                        }
                        edges.append(HashiEdge(a: p, b: isl, horizontal: true, cells: cells))
                    }
                    prev = isl
                }
            }
        }
        // Vertical edges: scan each column top to bottom.
        for c in 0..<w {
            var prev: Int? = nil
            for r in 0..<h {
                if let isl = islandAt[r * w + c] {
                    if let p = prev {
                        let pr = clues[p].r
                        var cells = [Int]()
                        if r - pr > 1 {
                            for rr in (pr + 1)..<r { cells.append(rr * w + c) }
                        }
                        edges.append(HashiEdge(a: p, b: isl, horizontal: false, cells: cells))
                    }
                    prev = isl
                }
            }
        }

        self.edges = edges

        // Incidence.
        var inc = Array(repeating: [Int](), count: clues.count)
        for (ei, e) in edges.enumerated() {
            inc[e.a].append(ei)
            inc[e.b].append(ei)
        }
        self.incident = inc

        // Crossings: two perpendicular edges cross iff they share an
        // intermediate cell. Parallel edges never share intermediate cells.
        var cellToEdges = [Int: [Int]]()
        for (ei, e) in edges.enumerated() {
            for cell in e.cells {
                cellToEdges[cell, default: []].append(ei)
            }
        }
        var cross = Array(repeating: Set<Int>(), count: edges.count)
        for (_, list) in cellToEdges where list.count > 1 {
            for i in 0..<list.count {
                for j in (i + 1)..<list.count {
                    cross[list[i]].insert(list[j])
                    cross[list[j]].insert(list[i])
                }
            }
        }
        self.crossing = cross.map { Array($0) }
    }
}
