import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var tab = 0

    var body: some View {
        ZStack {
            if !store.state.onboarded {
                OnboardingView()
                    .transition(.opacity)
            } else {
                mainTabs
            }
            ToastLayer(store: store)
        }
        .preferredColorScheme(.light)
        .onChange(of: scenePhase) { phase in
            if phase == .background { store.save() }
        }
    }

    private var mainTabs: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Group {
                    switch tab {
                    case 0: NavigationView { PlayView() }.navigationViewStyle(StackNavigationViewStyle())
                    case 1: NavigationView { DailyView() }.navigationViewStyle(StackNavigationViewStyle())
                    case 2: NavigationView { AwardsView() }.navigationViewStyle(StackNavigationViewStyle())
                    default: NavigationView { MoreView() }.navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                tabBar
            }
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Play", PlayTabGlyph())
            tabButton(1, "Daily", DailyTabGlyph())
            tabButton(2, "Awards", AwardsTabGlyph())
            tabButton(3, "More", MoreTabGlyph())
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            Palette.card
                .shadow(color: Palette.ink.opacity(0.06), radius: 6, y: -2)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton<G: Shape>(_ i: Int, _ label: String, _ glyph: G) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) { tab = i }
        } label: {
            VStack(spacing: 4) {
                glyph
                    .stroke(tab == i ? Palette.waterDeep : Palette.inkSoft,
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 24, height: 24)
                Text(label)
                    .font(.system(size: 11, weight: tab == i ? .bold : .medium))
                    .foregroundColor(tab == i ? Palette.waterDeep : Palette.inkSoft)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
