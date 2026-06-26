import SwiftUI

struct MoreView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        ZStack {
            WaterBackground()
            ScrollView {
                VStack(spacing: 16) {
                    ScreenTitle(title: "More", subtitle: "Learn the craft & adjust settings")
                        .padding(.top, 8)

                    NavigationLink(destination: CodexView()) {
                        menuRow(glyph: BookGlyph(), title: "How to Play",
                                subtitle: "Rules and deduction techniques")
                    }.buttonStyle(.plain)

                    NavigationLink(destination: SettingsView()) {
                        menuRow(glyph: GearGlyph(), title: "Settings",
                                subtitle: "Display, accessibility, privacy, reset")
                    }.buttonStyle(.plain)

                    aboutCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
    }

    private func menuRow<G: Shape>(glyph: G, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.waterDeep.opacity(0.14)).frame(width: 50, height: 50)
                glyph.stroke(Palette.waterDeep, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 24, height: 24)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(Palette.ink)
                Text(subtitle).font(.system(size: 12, weight: .medium)).foregroundColor(Palette.inkSoft)
            }
            Spacer()
            ChevronGlyph().stroke(Palette.inkSoft, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .frame(width: 12, height: 14)
        }
        .zenCard()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About Bridge Logic").font(.system(size: 15, weight: .bold)).foregroundColor(Palette.ink)
            Text("Every puzzle is generated and proven to have one unique, fully-logical solution by the built-in solver — no guessing required. Connect the islands, find your calm.")
                .font(.system(size: 13, weight: .medium)).foregroundColor(Palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 16) {
                miniStat("\(PuzzleLibrary.totalPuzzles)", "puzzles")
                miniStat("\(PuzzleLibrary.packs.count)", "packs")
                miniStat("5", "grid sizes")
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zenCard()
    }

    private func miniStat(_ v: String, _ l: String) -> some View {
        VStack(spacing: 2) {
            Text(v).font(.system(size: 20, weight: .black, design: .rounded)).foregroundColor(Palette.waterDeep)
            Text(l).font(.system(size: 11, weight: .medium)).foregroundColor(Palette.inkSoft)
        }
        .frame(maxWidth: .infinity)
    }
}
