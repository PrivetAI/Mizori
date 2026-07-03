import Foundation

// MARK: - Per-puzzle progress

/// Saved progress for a single puzzle. `mizoris` holds the player's mizori
/// count per edge (edge order is deterministic from the puzzle definition).
struct PuzzleRecord: Codable {
    var mizoris: [Int]
    var solved: Bool
    var stars: Int
    var bestTime: Int        // seconds, 0 = none
    var usedHint: Bool
    var hadError: Bool
    var elapsed: Int         // in-progress timer snapshot

    enum CodingKeys: String, CodingKey {
        case mizoris, solved, stars, bestTime, usedHint, hadError, elapsed
    }

    init() {
        mizoris = []
        solved = false
        stars = 0
        bestTime = 0
        usedHint = false
        hadError = false
        elapsed = 0
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        mizoris = (try? c.decodeIfPresent([Int].self, forKey: .mizoris)) ?? []
        solved = (try? c.decodeIfPresent(Bool.self, forKey: .solved)) ?? false
        stars = (try? c.decodeIfPresent(Int.self, forKey: .stars)) ?? 0
        bestTime = (try? c.decodeIfPresent(Int.self, forKey: .bestTime)) ?? 0
        usedHint = (try? c.decodeIfPresent(Bool.self, forKey: .usedHint)) ?? false
        hadError = (try? c.decodeIfPresent(Bool.self, forKey: .hadError)) ?? false
        elapsed = (try? c.decodeIfPresent(Int.self, forKey: .elapsed)) ?? 0
    }
}

// MARK: - Settings

struct GameSettings: Codable {
    var showRemaining: Bool          // show remaining-mizori counts on islands
    var colorblindMarker: Bool       // add a check glyph to satisfied islands
    var highlightCrossings: Bool     // flag illegal/over-filled live
    var confirmActions: Bool         // ask before restart

    enum CodingKeys: String, CodingKey {
        case showRemaining, colorblindMarker, highlightCrossings, confirmActions
    }

    init() {
        showRemaining = false
        colorblindMarker = false
        highlightCrossings = true
        confirmActions = true
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        showRemaining = (try? c.decodeIfPresent(Bool.self, forKey: .showRemaining)) ?? false
        colorblindMarker = (try? c.decodeIfPresent(Bool.self, forKey: .colorblindMarker)) ?? false
        highlightCrossings = (try? c.decodeIfPresent(Bool.self, forKey: .highlightCrossings)) ?? true
        confirmActions = (try? c.decodeIfPresent(Bool.self, forKey: .confirmActions)) ?? true
    }
}

// MARK: - Statistics

struct GameStats: Codable {
    var totalSolved: Int
    var perfectSolves: Int           // 3-star, no hint, no error
    var totalHints: Int
    var totalErrors: Int
    var totalSeconds: Int
    var solvedByDifficulty: [Int]    // count per HashiDifficulty (4)
    var solvedBySize: [String: Int]  // "9×9" -> count
    var bestTimeByDifficulty: [Int]  // seconds per difficulty, 0 = none

    enum CodingKeys: String, CodingKey {
        case totalSolved, perfectSolves, totalHints, totalErrors, totalSeconds
        case solvedByDifficulty, solvedBySize, bestTimeByDifficulty
    }

    init() {
        totalSolved = 0
        perfectSolves = 0
        totalHints = 0
        totalErrors = 0
        totalSeconds = 0
        solvedByDifficulty = [0, 0, 0, 0]
        solvedBySize = [:]
        bestTimeByDifficulty = [0, 0, 0, 0]
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        totalSolved = (try? c.decodeIfPresent(Int.self, forKey: .totalSolved)) ?? 0
        perfectSolves = (try? c.decodeIfPresent(Int.self, forKey: .perfectSolves)) ?? 0
        totalHints = (try? c.decodeIfPresent(Int.self, forKey: .totalHints)) ?? 0
        totalErrors = (try? c.decodeIfPresent(Int.self, forKey: .totalErrors)) ?? 0
        totalSeconds = (try? c.decodeIfPresent(Int.self, forKey: .totalSeconds)) ?? 0
        solvedByDifficulty = (try? c.decodeIfPresent([Int].self, forKey: .solvedByDifficulty)) ?? [0,0,0,0]
        if solvedByDifficulty.count < 4 { solvedByDifficulty += Array(repeating: 0, count: 4 - solvedByDifficulty.count) }
        solvedBySize = (try? c.decodeIfPresent([String: Int].self, forKey: .solvedBySize)) ?? [:]
        bestTimeByDifficulty = (try? c.decodeIfPresent([Int].self, forKey: .bestTimeByDifficulty)) ?? [0,0,0,0]
        if bestTimeByDifficulty.count < 4 { bestTimeByDifficulty += Array(repeating: 0, count: 4 - bestTimeByDifficulty.count) }
    }
}

// MARK: - Daily record

struct DailyRecord: Codable {
    var solvedKeys: [String]         // "yyyy-mm-dd" solved
    var lastSolvedKey: String        // most recent solved day
    var streak: Int
    var bestStreak: Int
    var progress: [String: PuzzleRecord]  // in-progress daily boards by key

    enum CodingKeys: String, CodingKey {
        case solvedKeys, lastSolvedKey, streak, bestStreak, progress
    }

    init() {
        solvedKeys = []
        lastSolvedKey = ""
        streak = 0
        bestStreak = 0
        progress = [:]
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        solvedKeys = (try? c.decodeIfPresent([String].self, forKey: .solvedKeys)) ?? []
        lastSolvedKey = (try? c.decodeIfPresent(String.self, forKey: .lastSolvedKey)) ?? ""
        streak = (try? c.decodeIfPresent(Int.self, forKey: .streak)) ?? 0
        bestStreak = (try? c.decodeIfPresent(Int.self, forKey: .bestStreak)) ?? 0
        progress = (try? c.decodeIfPresent([String: PuzzleRecord].self, forKey: .progress)) ?? [:]
    }
}

// MARK: - Root state

struct GameState: Codable {
    var records: [String: PuzzleRecord]   // puzzleID -> progress
    var settings: GameSettings
    var stats: GameStats
    var daily: DailyRecord
    var achievements: [String]            // unlocked ids
    var onboarded: Bool

    enum CodingKeys: String, CodingKey {
        case records, settings, stats, daily, achievements, onboarded
    }

    init() {
        records = [:]
        settings = GameSettings()
        stats = GameStats()
        daily = DailyRecord()
        achievements = []
        onboarded = false
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        records = (try? c.decodeIfPresent([String: PuzzleRecord].self, forKey: .records)) ?? [:]
        settings = (try? c.decodeIfPresent(GameSettings.self, forKey: .settings)) ?? GameSettings()
        stats = (try? c.decodeIfPresent(GameStats.self, forKey: .stats)) ?? GameStats()
        daily = (try? c.decodeIfPresent(DailyRecord.self, forKey: .daily)) ?? DailyRecord()
        achievements = (try? c.decodeIfPresent([String].self, forKey: .achievements)) ?? []
        onboarded = (try? c.decodeIfPresent(Bool.self, forKey: .onboarded)) ?? false
    }
}
