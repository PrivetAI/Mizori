import SwiftUI
import Foundation

enum ConnectResult { case applied, illegalCross, noChannel, atMax }

/// Drives one active puzzle: the player's mizori counts, selection, undo,
/// timer, hints, error checking and solved detection.
final class BoardSession: ObservableObject {
    let puzzle: HashiPuzzle
    let graph: HashiBoardGraph
    let difficulty: HashiDifficulty
    let size: HashiGridSize
    let solution: [Int]

    @Published var values: [Int]
    @Published var selected: Int? = nil
    @Published var elapsed: Int = 0
    @Published var solved = false
    @Published var errorEdges: Set<Int> = []
    @Published var errorIslands: Set<Int> = []
    @Published var illegalFlash = false

    private(set) var usedHint = false
    private(set) var hadError = false
    private var undoStack: [[Int]] = []
    private let solver: HashiSolver

    /// sorted island-pair -> edge index
    private var pairToEdge: [Int: Int] = [:]

    var canUndo: Bool { !undoStack.isEmpty }

    init(puzzle: HashiPuzzle, difficulty: HashiDifficulty, size: HashiGridSize,
         saved: PuzzleRecord?) {
        self.puzzle = puzzle
        self.difficulty = difficulty
        self.size = size
        let g = HashiBoardGraph(puzzle)
        self.graph = g
        self.solver = HashiSolver(g)
        self.solution = solver.solvedValues() ?? Array(repeating: 0, count: g.edges.count)

        if let saved = saved, saved.mizoris.count == g.edges.count {
            self.values = saved.mizoris
            self.elapsed = saved.elapsed
            self.usedHint = saved.usedHint
            self.hadError = saved.hadError
        } else {
            self.values = Array(repeating: 0, count: g.edges.count)
        }

        for (i, e) in g.edges.enumerated() {
            pairToEdge[pairKey(e.a, e.b)] = i
        }
        recomputeSolved()
    }

    private func pairKey(_ a: Int, _ b: Int) -> Int {
        let lo = min(a, b), hi = max(a, b)
        return lo * 10000 + hi
    }

    // MARK: Queries

    func degree(of island: Int) -> Int {
        var sum = 0
        for e in graph.incident[island] { sum += values[e] }
        return sum
    }

    func need(of island: Int) -> Int { puzzle.clues[island].need }
    func remaining(of island: Int) -> Int { need(of: island) - degree(of: island) }
    func isSatisfied(_ island: Int) -> Bool { degree(of: island) == need(of: island) }
    func isOver(_ island: Int) -> Bool { degree(of: island) > need(of: island) }

    func edgeBetween(_ a: Int, _ b: Int) -> Int? { pairToEdge[pairKey(a, b)] }

    var satisfiedCount: Int {
        (0..<puzzle.clues.count).filter { isSatisfied($0) }.count
    }
    var islandCount: Int { puzzle.clues.count }
    var networkConnected: Bool { solver.isConnected(values) }
    var hasAnyMizori: Bool { values.contains { $0 > 0 } }

    /// Number of connected components over currently-placed mizoris.
    func componentCount() -> Int {
        let n = puzzle.clues.count
        var parent = Array(0..<n)
        func find(_ x: Int) -> Int {
            var r = x
            while parent[r] != r { parent[r] = parent[parent[r]]; r = parent[r] }
            return r
        }
        for (i, e) in graph.edges.enumerated() where values[i] > 0 {
            let ra = find(e.a), rb = find(e.b)
            if ra != rb { parent[ra] = rb }
        }
        var roots = Set<Int>()
        for i in 0..<n { roots.insert(find(i)) }
        return roots.count
    }

    // MARK: Interaction

    func tapIsland(_ i: Int) {
        if let s = selected {
            if s == i {
                selected = nil
            } else if edgeBetween(s, i) != nil {
                _ = connect(s, i)
                selected = nil
            } else {
                selected = i
            }
        } else {
            selected = i
        }
    }

    func clearSelection() { selected = nil }

    @discardableResult
    func connect(_ a: Int, _ b: Int) -> ConnectResult {
        guard let e = edgeBetween(a, b) else { return .noChannel }
        return cycle(edge: e)
    }

    @discardableResult
    func cycle(edge e: Int) -> ConnectResult {
        let current = values[e]
        let next = (current + 1) % 3
        if next >= 1 {
            // would-be mizori must not cross an existing mizori
            for f in graph.crossing[e] where values[f] >= 1 {
                triggerIllegal()
                return .illegalCross
            }
        }
        pushUndo()
        values[e] = next
        afterChange()
        return .applied
    }

    private func triggerIllegal() {
        illegalFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.illegalFlash = false
        }
    }

    private func pushUndo() {
        undoStack.append(values)
        if undoStack.count > 200 { undoStack.removeFirst() }
    }

    func undo() {
        guard let prev = undoStack.popLast() else { return }
        values = prev
        errorEdges = []
        errorIslands = []
        recomputeSolved()
    }

    func restart() {
        pushUndo()
        values = Array(repeating: 0, count: graph.edges.count)
        elapsed = 0
        errorEdges = []
        errorIslands = []
        selected = nil
        solved = false
    }

    private func afterChange() {
        errorEdges = []
        errorIslands = []
        recomputeSolved()
    }

    func recomputeSolved() {
        for i in 0..<puzzle.clues.count where degree(of: i) != need(of: i) {
            solved = false
            return
        }
        solved = solver.isConnected(values)
    }

    // MARK: Hint

    /// Applies the next forced mizori. Returns its reason for display.
    func hint() -> String? {
        guard let step = solver.nextHint(playerValues: values) else { return nil }
        // Apply, respecting selection/undo.
        pushUndo()
        values[step.edge] = step.value
        usedHint = true
        afterChange()
        let a = graph.edges[step.edge].a
        let locA = puzzle.clues[a]
        return "Mizori near (\(locA.r + 1),\(locA.c + 1)) and its neighbour: \(step.reason)"
    }

    func hintTargetEdge() -> Int? {
        solver.nextHint(playerValues: values)?.edge
    }

    // MARK: Error check

    /// Highlights edges/islands that conflict with the unique solution.
    @discardableResult
    func runCheck() -> Bool {
        var badEdges = Set<Int>()
        for e in 0..<values.count where values[e] != solution[e] {
            // only flag a placed mizori that's wrong (too many / not in solution)
            if values[e] > solution[e] { badEdges.insert(e) }
        }
        var badIslands = Set<Int>()
        for i in 0..<puzzle.clues.count where isOver(i) { badIslands.insert(i) }
        errorEdges = badEdges
        errorIslands = badIslands
        let hasErrors = !badEdges.isEmpty || !badIslands.isEmpty
        if hasErrors { hadError = true }
        return hasErrors
    }

    func tick() {
        guard !solved else { return }
        elapsed += 1
    }
}
