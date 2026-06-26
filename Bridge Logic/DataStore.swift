import SwiftUI
import Foundation

/// Central observable store: owns the persisted GameState, applies game events,
/// tracks achievements + statistics, and exposes a toast stream.
final class DataStore: ObservableObject {
    @Published private(set) var state: GameState
    @Published var toasts: [ToastItem] = []

    private let saveKey = "blg.state.v1"

    init() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(GameState.self, from: data) {
            state = decoded
        } else {
            state = GameState()
        }
    }

    // MARK: Persistence

    func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    // MARK: Settings

    var settings: GameSettings { state.settings }

    func updateSettings(_ block: (inout GameSettings) -> Void) {
        block(&state.settings)
        save()
    }

    func completeOnboarding() {
        state.onboarded = true
        save()
    }

    func resetProgress() {
        state = GameState()
        // keep onboarded so they don't see it again
        state.onboarded = true
        save()
    }

    // MARK: Records

    func record(for id: String) -> PuzzleRecord? { state.records[id] }

    func saveProgress(id: String, bridges: [Int], elapsed: Int, hadError: Bool, usedHint: Bool) {
        var rec = state.records[id] ?? PuzzleRecord()
        rec.bridges = bridges
        rec.elapsed = elapsed
        if hadError { rec.hadError = true }
        if usedHint { rec.usedHint = true }
        state.records[id] = rec
        save()
    }

    // MARK: Daily progress

    func dailyRecord(key: String) -> PuzzleRecord? { state.daily.progress[key] }

    func saveDailyProgress(key: String, bridges: [Int], elapsed: Int, hadError: Bool, usedHint: Bool) {
        var rec = state.daily.progress[key] ?? PuzzleRecord()
        rec.bridges = bridges
        rec.elapsed = elapsed
        if hadError { rec.hadError = true }
        if usedHint { rec.usedHint = true }
        state.daily.progress[key] = rec
        save()
    }

    // MARK: Completion

    /// Called when a board reaches a solved state. Computes stars, updates
    /// stats + achievements, and fires toasts. Returns the awarded stars.
    @discardableResult
    func completePuzzle(id: String, difficulty: HashiDifficulty, size: HashiGridSize,
                        seconds: Int, usedHint: Bool, hadError: Bool,
                        isDaily: Bool, dailyKey: String?) -> Int {
        let stars = computeStars(difficulty: difficulty, seconds: seconds,
                                 usedHint: usedHint, hadError: hadError)
        let firstSolve: Bool

        if isDaily, let key = dailyKey {
            firstSolve = !state.daily.solvedKeys.contains(key)
            var rec = state.daily.progress[key] ?? PuzzleRecord()
            rec.solved = true
            rec.stars = max(rec.stars, stars)
            rec.usedHint = rec.usedHint || usedHint
            rec.hadError = rec.hadError || hadError
            rec.elapsed = seconds
            if rec.bestTime == 0 || seconds < rec.bestTime { rec.bestTime = seconds }
            state.daily.progress[key] = rec
            if firstSolve {
                state.daily.solvedKeys.append(key)
                updateStreak(newKey: key)
            }
        } else {
            firstSolve = !(state.records[id]?.solved ?? false)
            var rec = state.records[id] ?? PuzzleRecord()
            rec.solved = true
            rec.stars = max(rec.stars, stars)
            rec.usedHint = rec.usedHint || usedHint
            rec.hadError = rec.hadError || hadError
            if rec.bestTime == 0 || seconds < rec.bestTime { rec.bestTime = seconds }
            state.records[id] = rec
        }

        // Stats (count each puzzle's first solve only).
        if firstSolve {
            state.stats.totalSolved += 1
            state.stats.solvedByDifficulty[difficulty.rawValue] += 1
            state.stats.solvedBySize[size.label, default: 0] += 1
            if stars == 3 && !usedHint && !hadError { state.stats.perfectSolves += 1 }
            let bt = state.stats.bestTimeByDifficulty[difficulty.rawValue]
            if bt == 0 || seconds < bt { state.stats.bestTimeByDifficulty[difficulty.rawValue] = seconds }
        }
        state.stats.totalSeconds += seconds

        save()
        evaluateAchievements()
        pushToast(ToastItem(kind: .success,
                            title: firstSolve ? "Solved!" : "Solved again",
                            message: "\(stars)-star • \(difficulty.title)"))
        return stars
    }

    func registerHintUsed() {
        state.stats.totalHints += 1
        save()
    }

    func registerError() {
        state.stats.totalErrors += 1
        save()
    }

    private func computeStars(difficulty: HashiDifficulty, seconds: Int,
                              usedHint: Bool, hadError: Bool) -> Int {
        if !usedHint && !hadError { return 3 }
        if !usedHint || !hadError { return 2 }
        return 1
    }

    private func updateStreak(newKey: String) {
        // newKey is "yyyy-mm-dd". Compute consecutive-day streak.
        let prev = state.daily.lastSolvedKey
        if prev.isEmpty {
            state.daily.streak = 1
        } else if let p = DataStore.date(from: prev),
                  let n = DataStore.date(from: newKey) {
            let days = Calendar(identifier: .gregorian)
                .dateComponents([.day], from: p, to: n).day ?? 99
            if days == 1 {
                state.daily.streak += 1
            } else if days == 0 {
                // same day, ignore
            } else {
                state.daily.streak = 1
            }
        } else {
            state.daily.streak = 1
        }
        state.daily.lastSolvedKey = newKey
        if state.daily.streak > state.daily.bestStreak {
            state.daily.bestStreak = state.daily.streak
        }
    }

    static func date(from key: String) -> Date? {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        f.timeZone = TimeZone(identifier: "UTC")
        return f.date(from: key)
    }

    /// Recompute the live streak considering missed days (call on app open).
    func refreshStreak(today: Date) {
        guard !state.daily.lastSolvedKey.isEmpty else { return }
        let todayKey = PuzzleLibrary.dailyKey(for: today)
        guard let last = DataStore.date(from: state.daily.lastSolvedKey),
              let now = DataStore.date(from: todayKey) else { return }
        let days = Calendar(identifier: .gregorian)
            .dateComponents([.day], from: last, to: now).day ?? 99
        if days > 1 {
            state.daily.streak = 0
            save()
        }
    }

    // MARK: Achievements

    private func evaluateAchievements() {
        let unlocked = Achievements.unlocked(in: state)
        let newly = unlocked.filter { !state.achievements.contains($0) }
        if !newly.isEmpty {
            state.achievements = unlocked
            save()
            for id in newly {
                if let a = Achievements.all.first(where: { $0.id == id }) {
                    pushToast(ToastItem(kind: .award, title: "Achievement",
                                        message: a.title))
                }
            }
        }
    }

    func isUnlocked(_ id: String) -> Bool { state.achievements.contains(id) }

    // MARK: Toasts

    func pushToast(_ item: ToastItem) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            toasts.append(item)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.6) { [weak self] in
            withAnimation(.easeInOut(duration: 0.3)) {
                self?.toasts.removeAll { $0.id == item.id }
            }
        }
    }

    // MARK: Derived helpers for UI

    func packProgress(_ pack: PuzzlePack) -> (solved: Int, stars: Int) {
        var solved = 0, stars = 0
        for i in 0..<pack.count {
            if let r = state.records[pack.puzzleID(for: i)], r.solved {
                solved += 1
                stars += r.stars
            }
        }
        return (solved, stars)
    }

    var totalStars: Int {
        var s = state.records.values.reduce(0) { $0 + ($1.solved ? $1.stars : 0) }
        s += state.daily.progress.values.reduce(0) { $0 + ($1.solved ? $1.stars : 0) }
        return s
    }
}
