import Foundation

/// A named collection of puzzles sharing a grid size and difficulty tier.
struct PuzzlePack: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let size: HashiGridSize
    let difficulty: HashiDifficulty
    let count: Int
    let baseSeed: UInt64

    func seed(for index: Int) -> UInt64 {
        mixSeed([baseSeed, UInt64(index), 0xA11CE])
    }

    func puzzleID(for index: Int) -> String {
        "\(id)#\(index)"
    }
}

/// The catalogue of all shipped packs + the daily puzzle definition.
/// Puzzles are generated deterministically on demand (and cached) — only
/// metadata lives here, so the list screens are instant.
enum PuzzleLibrary {

    static let packs: [PuzzlePack] = [
        PuzzlePack(id: "cove",     title: "Quiet Cove",      subtitle: "First steps on calm water",
                   size: .s7,  difficulty: .easy,   count: 14, baseSeed: 0x1001),
        PuzzlePack(id: "lagoon",   title: "Sunlit Lagoon",   subtitle: "Small grids, gentle logic",
                   size: .s7,  difficulty: .medium, count: 14, baseSeed: 0x1002),
        PuzzlePack(id: "shoals",   title: "Shallow Shoals",  subtitle: "Room to stretch your mizoris",
                   size: .s9,  difficulty: .easy,   count: 14, baseSeed: 0x1003),
        PuzzlePack(id: "reef",     title: "Coral Reef",      subtitle: "Crossing channels appear",
                   size: .s9,  difficulty: .medium, count: 14, baseSeed: 0x1004),
        PuzzlePack(id: "atoll",    title: "Hidden Atoll",    subtitle: "Elimination required",
                   size: .s9,  difficulty: .hard,   count: 14, baseSeed: 0x1005),
        PuzzlePack(id: "strait",   title: "Windward Strait", subtitle: "Medium grids, sharper turns",
                   size: .s11, difficulty: .medium, count: 14, baseSeed: 0x1006),
        PuzzlePack(id: "channel",  title: "Deep Channel",    subtitle: "Chains of deduction",
                   size: .s11, difficulty: .hard,   count: 14, baseSeed: 0x1007),
        PuzzlePack(id: "trench",   title: "Mariner's Trench", subtitle: "Only for the seasoned",
                   size: .s11, difficulty: .expert, count: 14, baseSeed: 0x1008),
        PuzzlePack(id: "archipel", title: "Grand Archipelago", subtitle: "Sprawling hard boards",
                   size: .s13, difficulty: .hard,   count: 14, baseSeed: 0x1009),
        PuzzlePack(id: "maelstrom", title: "The Maelstrom",  subtitle: "Expert tangles, 13×13",
                   size: .s13, difficulty: .expert, count: 14, baseSeed: 0x100A),
        PuzzlePack(id: "leviathan", title: "Leviathan Sea",  subtitle: "The largest, deepest grids",
                   size: .s17, difficulty: .expert, count: 14, baseSeed: 0x100B),
    ]

    static var totalPuzzles: Int { packs.reduce(0) { $0 + $1.count } }

    static func pack(id: String) -> PuzzlePack? {
        packs.first { $0.id == id }
    }

    // MARK: Generation + cache

    private static var cache = [String: HashiPuzzle]()
    private static let cacheLock = NSLock()

    private static func cached(_ key: String) -> HashiPuzzle? {
        cacheLock.lock(); defer { cacheLock.unlock() }
        return cache[key]
    }
    private static func store(_ key: String, _ puzzle: HashiPuzzle) {
        cacheLock.lock(); defer { cacheLock.unlock() }
        cache[key] = puzzle
    }

    static func puzzle(pack: PuzzlePack, index: Int) -> HashiPuzzle {
        let key = pack.puzzleID(for: index)
        if let c = cached(key) { return c }
        let gen = HashiGenerator(size: pack.size, target: pack.difficulty)
        let result = gen.generate(seed: pack.seed(for: index))
        store(key, result.puzzle)
        return result.puzzle
    }

    // MARK: Daily puzzle

    static func dailyKey(for date: Date) -> String {
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let y = comps.year ?? 2026, m = comps.month ?? 1, d = comps.day ?? 1
        return String(format: "%04d-%02d-%02d", y, m, d)
    }

    static func dailyDifficulty(for date: Date) -> HashiDifficulty {
        let cal = Calendar(identifier: .gregorian)
        let wd = cal.component(.weekday, from: date) // 1=Sun
        switch wd {
        case 1, 7: return .hard            // weekends a touch tougher
        case 2: return .easy
        case 3, 5: return .medium
        case 4: return .hard
        default: return .expert            // Saturday(7 handled) -> Friday(6)
        }
    }

    static func dailySize(for date: Date) -> HashiGridSize {
        let diff = dailyDifficulty(for: date)
        switch diff {
        case .easy: return .s7
        case .medium: return .s9
        case .hard: return .s11
        case .expert: return .s13
        }
    }

    static func dailyPuzzle(for date: Date) -> (id: String, puzzle: HashiPuzzle, difficulty: HashiDifficulty, size: HashiGridSize) {
        let key = dailyKey(for: date)
        let diff = dailyDifficulty(for: date)
        let size = dailySize(for: date)
        let cacheKey = "daily-\(key)"
        if let c = cached(cacheKey) {
            return (key, c, diff, size)
        }
        let cal = Calendar(identifier: .gregorian)
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let seedNum = UInt64((comps.year ?? 2026) * 10000 + (comps.month ?? 1) * 100 + (comps.day ?? 1))
        let gen = HashiGenerator(size: size, target: diff)
        let result = gen.generate(seed: mixSeed([seedNum, 0xDA117]))
        store(cacheKey, result.puzzle)
        return (key, result.puzzle, diff, size)
    }
}
