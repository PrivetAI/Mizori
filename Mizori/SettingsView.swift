import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: DataStore
    @Environment(\.presentationMode) private var presentationMode

    @State private var showPrivacy = false
    @State private var confirmReset = false

    private let privacyURL = "https://roadplannertriporganizer.org/click.php"

    var body: some View {
        ZStack {
            WaterBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack { BackButton { presentationMode.wrappedValue.dismiss() }; Spacer() }
                    ScreenTitle(title: "Settings", subtitle: "Tune your experience")

                    VStack(spacing: 14) {
                        ZenToggle(title: "Show remaining count",
                                  detail: "Islands display mizoris still needed instead of their total.",
                                  isOn: bind(\.showRemaining))
                        Divider()
                        ZenToggle(title: "Colorblind marker",
                                  detail: "Satisfied islands show a check mark, not just a color.",
                                  isOn: bind(\.colorblindMarker))
                        Divider()
                        ZenToggle(title: "Live error highlight",
                                  detail: "Flag over-filled islands as you play.",
                                  isOn: bind(\.highlightCrossings))
                        Divider()
                        ZenToggle(title: "Confirm restart",
                                  detail: "Ask before clearing a board you’re working on.",
                                  isOn: bind(\.confirmActions))
                    }
                    .zenCard()

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Privacy & Data").font(.system(size: 14, weight: .bold)).foregroundColor(Palette.ink)
                        Button { showPrivacy = true } label: {
                            HStack {
                                ShieldGlyph().stroke(Palette.waterDeep, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                    .frame(width: 18, height: 20)
                                Text("Privacy Policy").font(.system(size: 15, weight: .semibold)).foregroundColor(Palette.ink)
                                Spacer()
                                ChevronGlyph().stroke(Palette.inkSoft, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                                    .frame(width: 11, height: 13)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Text("Mizori stores all progress on your device only. No account, no tracking, no network play.")
                            .font(.system(size: 12, weight: .medium)).foregroundColor(Palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .zenCard()

                    Button { confirmReset = true } label: {
                        Text("Reset All Progress")
                            .font(.system(size: 15, weight: .bold)).foregroundColor(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Palette.danger))
                    }
                    .buttonStyle(.plain)

                    Text("Mizori v1.0")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(Palette.inkSoft)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showPrivacy) {
            MizoriWaterPanel(urlString: privacyURL)
                .edgesIgnoringSafeArea(.bottom)
                .background(Color.black.ignoresSafeArea())
        }
        .alert(isPresented: $confirmReset) {
            Alert(title: Text("Reset all progress?"),
                  message: Text("This permanently clears every solved puzzle, streak, stat and achievement."),
                  primaryButton: .destructive(Text("Reset")) {
                      store.resetProgress()
                      store.pushToast(ToastItem(kind: .info, title: "Progress reset", message: "A fresh start awaits."))
                  },
                  secondaryButton: .cancel())
        }
    }

    private func bind(_ key: WritableKeyPath<GameSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { store.settings[keyPath: key] },
            set: { newVal in store.updateSettings { $0[keyPath: key] = newVal } })
    }
}
