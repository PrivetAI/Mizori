import SwiftUI

struct DailyView: View {
    @EnvironmentObject var store: DataStore
    @State private var playing = false
    private let today = Date()

    private var key: String { PuzzleLibrary.dailyKey(for: today) }
    private var difficulty: HashiDifficulty { PuzzleLibrary.dailyDifficulty(for: today) }
    private var size: HashiGridSize { PuzzleLibrary.dailySize(for: today) }
    private var solvedToday: Bool { store.state.daily.solvedKeys.contains(key) }
    private var rec: PuzzleRecord? { store.dailyRecord(key: key) }

    var body: some View {
        ZStack {
            WaterBackground()
            ScrollView {
                VStack(spacing: 18) {
                    ScreenTitle(title: "Daily", subtitle: prettyDate)
                        .padding(.top, 8)

                    streakCard
                    todayCard
                    historyCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: $playing) {
            BoardLoaderView(source: .daily(today), onNext: nil, onClose: { playing = false })
                .environmentObject(store)
        }
        .onAppear { store.refreshStreak(today: today) }
    }

    private var prettyDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: today)
    }

    private var streakCard: some View {
        HStack(spacing: 16) {
            streakStat(value: "\(store.state.daily.streak)", label: "Current streak")
            Divider().frame(height: 36)
            streakStat(value: "\(store.state.daily.bestStreak)", label: "Best streak")
            Divider().frame(height: 36)
            streakStat(value: "\(store.state.daily.solvedKeys.count)", label: "Days solved")
        }
        .frame(maxWidth: .infinity)
        .zenCard()
    }

    private func streakStat(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(.system(size: 24, weight: .black, design: .rounded)).foregroundColor(Palette.waterDeep)
            Text(label).font(.system(size: 11, weight: .medium)).foregroundColor(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity)
    }

    private var todayCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle().fill(Palette.difficultyColor(difficulty).opacity(0.18)).frame(width: 84, height: 84)
                DailyTabGlyph().stroke(Palette.difficultyColor(difficulty),
                                       style: StrokeStyle(lineWidth: 2.6, lineCap: .round, lineJoin: .round))
                    .frame(width: 44, height: 44)
            }
            HStack(spacing: 8) {
                DifficultyPill(difficulty: difficulty)
                Text(size.label).font(.system(size: 12, weight: .bold))
                    .foregroundColor(Palette.ink)
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Capsule().fill(Palette.card)).overlay(Capsule().stroke(Palette.cardEdge, lineWidth: 1))
            }
            if solvedToday {
                StarRow(filled: rec?.stars ?? 0, total: 3, size: 22)
                Text("Solved in \(formatTime(rec?.bestTime ?? 0))")
                    .font(.system(size: 13, weight: .semibold)).foregroundColor(Palette.inkSoft)
                PrimaryButton(title: "Play Again", fill: Palette.sandDeep) { playing = true }
            } else {
                PrimaryButton(title: (rec?.bridges.contains { $0 > 0 } ?? false) ? "Resume Today’s Puzzle" : "Play Today’s Puzzle") {
                    playing = true
                }
            }
        }
        .frame(maxWidth: .infinity)
        .zenCard(padding: 20)
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Last 7 days").font(.system(size: 14, weight: .bold)).foregroundColor(Palette.ink)
            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { back in
                    let date = Calendar(identifier: .gregorian).date(byAdding: .day, value: -6 + back, to: today)!
                    let k = PuzzleLibrary.dailyKey(for: date)
                    let done = store.state.daily.solvedKeys.contains(k)
                    VStack(spacing: 4) {
                        ZStack {
                            Circle().fill(done ? Palette.satisfied : Palette.cardEdge.opacity(0.5))
                                .frame(width: 30, height: 30)
                            if done {
                                CheckGlyph().stroke(.white, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                    .frame(width: 14, height: 14)
                            }
                        }
                        Text(dayLetter(date)).font(.system(size: 10, weight: .bold)).foregroundColor(Palette.inkSoft)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zenCard()
    }

    private func dayLetter(_ d: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEEE"
        return f.string(from: d)
    }
}
