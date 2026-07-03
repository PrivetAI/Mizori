import SwiftUI

struct AwardsView: View {
    @EnvironmentObject var store: DataStore
    @State private var tab = 0   // 0 achievements, 1 stats

    var body: some View {
        ZStack {
            WaterBackground()
            VStack(spacing: 0) {
                ScreenTitle(title: "Awards", subtitle: "Your voyage so far")
                    .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 12)
                segmented
                ScrollView {
                    if tab == 0 { achievementsList } else { statsList }
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var segmented: some View {
        HStack(spacing: 8) {
            segButton("Achievements", 0)
            segButton("Statistics", 1)
        }
        .padding(.horizontal, 16).padding(.bottom, 10)
    }

    private func segButton(_ title: String, _ i: Int) -> some View {
        Button { withAnimation(.easeInOut(duration: 0.2)) { tab = i } } label: {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(tab == i ? .white : Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 12).fill(tab == i ? Palette.waterDeep : Palette.card))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Palette.cardEdge, lineWidth: tab == i ? 0 : 1))
        }
        .buttonStyle(.plain)
    }

    private var unlockedCount: Int {
        Achievements.all.filter { store.isUnlocked($0.id) }.count
    }

    private var achievementsList: some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(unlockedCount) of \(Achievements.all.count) unlocked")
                    .font(.system(size: 13, weight: .bold)).foregroundColor(Palette.inkSoft)
                Spacer()
            }
            ForEach(Achievements.all) { a in
                let on = store.isUnlocked(a.id)
                HStack(spacing: 12) {
                    ZStack {
                        Circle().fill(on ? Palette.star.opacity(0.2) : Palette.cardEdge.opacity(0.4))
                            .frame(width: 46, height: 46)
                        if on {
                            StarShape(points: 5).fill(Palette.star).frame(width: 22, height: 22)
                        } else {
                            LockGlyph().stroke(Palette.inkSoft, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                .frame(width: 20, height: 20)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(a.title).font(.system(size: 15, weight: .bold))
                            .foregroundColor(on ? Palette.ink : Palette.inkSoft)
                        Text(a.detail).font(.system(size: 12, weight: .medium)).foregroundColor(Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .zenCard()
                .opacity(on ? 1 : 0.75)
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 90)
    }

    private var statsList: some View {
        let s = store.state.stats
        return VStack(spacing: 12) {
            HStack(spacing: 12) {
                statBox("\(s.totalSolved)", "Puzzles solved")
                statBox("\(store.totalStars)", "Stars earned")
            }
            HStack(spacing: 12) {
                statBox("\(s.perfectSolves)", "Perfect (3★)")
                statBox("\(store.state.daily.bestStreak)", "Best streak")
            }
            HStack(spacing: 12) {
                statBox("\(s.totalHints)", "Hints used")
                statBox(formatTime(s.totalSeconds), "Time played")
            }

            sectionCard(title: "By difficulty") {
                ForEach(HashiDifficulty.allCases, id: \.rawValue) { d in
                    statRow(label: d.title, value: "\(s.solvedByDifficulty[d.rawValue])",
                            extra: s.bestTimeByDifficulty[d.rawValue] > 0 ? "best \(formatTime(s.bestTimeByDifficulty[d.rawValue]))" : "—",
                            color: Palette.difficultyColor(d))
                }
            }

            sectionCard(title: "By grid size") {
                ForEach(HashiGridSize.all, id: \.label) { gs in
                    statRow(label: gs.label, value: "\(s.solvedBySize[gs.label] ?? 0)", extra: "solved", color: Palette.waterDeep)
                }
            }
        }
        .padding(.horizontal, 16).padding(.bottom, 90)
    }

    private func statBox(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.system(size: 26, weight: .black, design: .rounded)).foregroundColor(Palette.waterDeep)
            Text(label).font(.system(size: 12, weight: .medium)).foregroundColor(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .zenCard()
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 14, weight: .bold)).foregroundColor(Palette.ink)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zenCard()
    }

    private func statRow(label: String, value: String, extra: String, color: Color) -> some View {
        HStack {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(label).font(.system(size: 14, weight: .semibold)).foregroundColor(Palette.ink)
            Spacer()
            Text(value).font(.system(size: 14, weight: .heavy)).foregroundColor(Palette.ink)
            Text(extra).font(.system(size: 11, weight: .medium)).foregroundColor(Palette.inkSoft)
                .frame(width: 78, alignment: .trailing)
        }
    }
}
