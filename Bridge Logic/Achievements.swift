import Foundation

struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    /// Returns true when unlocked for the given state.
    let test: (GameState) -> Bool
}

enum Achievements {

    static let all: [Achievement] = [
        Achievement(id: "first_bridge", title: "First Crossing",
                    detail: "Solve your very first puzzle.") { $0.stats.totalSolved >= 1 },
        Achievement(id: "five_solved", title: "Island Hopper",
                    detail: "Solve 5 puzzles.") { $0.stats.totalSolved >= 5 },
        Achievement(id: "twenty_solved", title: "Cartographer",
                    detail: "Solve 20 puzzles.") { $0.stats.totalSolved >= 20 },
        Achievement(id: "fifty_solved", title: "Master Navigator",
                    detail: "Solve 50 puzzles.") { $0.stats.totalSolved >= 50 },
        Achievement(id: "hundred_solved", title: "Sea Legend",
                    detail: "Solve 100 puzzles.") { $0.stats.totalSolved >= 100 },
        Achievement(id: "first_perfect", title: "Clean Lines",
                    detail: "Earn a 3-star perfect solve.") { $0.stats.perfectSolves >= 1 },
        Achievement(id: "ten_perfect", title: "Precision Pilot",
                    detail: "Earn 10 perfect solves.") { $0.stats.perfectSolves >= 10 },
        Achievement(id: "thirty_perfect", title: "Flawless Fleet",
                    detail: "Earn 30 perfect solves.") { $0.stats.perfectSolves >= 30 },
        Achievement(id: "no_hint_solver", title: "Unaided",
                    detail: "Solve 15 puzzles without a single hint.") {
            $0.stats.totalSolved >= 15 && $0.stats.totalHints == 0
        },
        Achievement(id: "easy_done", title: "Calm Waters",
                    detail: "Solve 10 Easy puzzles.") { $0.stats.solvedByDifficulty[0] >= 10 },
        Achievement(id: "medium_done", title: "Steady Current",
                    detail: "Solve 10 Medium puzzles.") { $0.stats.solvedByDifficulty[1] >= 10 },
        Achievement(id: "hard_done", title: "Rough Seas",
                    detail: "Solve 10 Hard puzzles.") { $0.stats.solvedByDifficulty[2] >= 10 },
        Achievement(id: "expert_done", title: "Deep Diver",
                    detail: "Solve 10 Expert puzzles.") { $0.stats.solvedByDifficulty[3] >= 10 },
        Achievement(id: "first_expert", title: "Into the Deep",
                    detail: "Solve your first Expert puzzle.") { $0.stats.solvedByDifficulty[3] >= 1 },
        Achievement(id: "big_grid", title: "Grand Voyage",
                    detail: "Solve a 17×17 puzzle.") { ($0.stats.solvedBySize["17×17"] ?? 0) >= 1 },
        Achievement(id: "all_sizes", title: "Every Shore",
                    detail: "Solve a puzzle of every grid size.") { st in
            ["7×7","9×9","11×11","13×13","17×17"].allSatisfy { (st.stats.solvedBySize[$0] ?? 0) >= 1 }
        },
        Achievement(id: "daily_1", title: "Daily Ritual",
                    detail: "Solve a Daily Puzzle.") { !$0.daily.solvedKeys.isEmpty },
        Achievement(id: "streak_3", title: "On a Roll",
                    detail: "Reach a 3-day Daily streak.") { $0.daily.bestStreak >= 3 },
        Achievement(id: "streak_7", title: "Tide Keeper",
                    detail: "Reach a 7-day Daily streak.") { $0.daily.bestStreak >= 7 },
        Achievement(id: "streak_30", title: "Lunar Cycle",
                    detail: "Reach a 30-day Daily streak.") { $0.daily.bestStreak >= 30 },
        Achievement(id: "pack_clear", title: "Cove Cleared",
                    detail: "Finish every puzzle in a pack.") { state in
            PuzzleLibrary.packs.contains { pack in
                (0..<pack.count).allSatisfy { state.records[pack.puzzleID(for: $0)]?.solved == true }
            }
        },
        Achievement(id: "all_packs", title: "Archipelago Sovereign",
                    detail: "Finish every puzzle in every pack.") { state in
            PuzzleLibrary.packs.allSatisfy { pack in
                (0..<pack.count).allSatisfy { state.records[pack.puzzleID(for: $0)]?.solved == true }
            }
        },
    ]

    static func unlocked(in state: GameState) -> [String] {
        all.filter { $0.test(state) }.map { $0.id }
    }
}
