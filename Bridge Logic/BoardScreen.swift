import SwiftUI

/// The full puzzle play screen: HUD + Canvas board + controls + solved overlay.
struct BoardScreen: View {
    @EnvironmentObject var store: DataStore

    let puzzle: HashiPuzzle
    let difficulty: HashiDifficulty
    let size: HashiGridSize
    let title: String
    let subtitle: String
    let puzzleID: String
    let isDaily: Bool
    let dailyKey: String?
    var onNext: (() -> Void)? = nil
    let onClose: () -> Void

    @StateObject private var session: BoardSession
    @State private var showSolved = false
    @State private var awardedStars = 0
    @State private var hintMessage: String? = nil
    @State private var hintEdge: Int? = nil
    @State private var confirmRestart = false

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(puzzle: HashiPuzzle, difficulty: HashiDifficulty, size: HashiGridSize,
         title: String, subtitle: String, puzzleID: String,
         isDaily: Bool, dailyKey: String?, saved: PuzzleRecord?,
         onNext: (() -> Void)? = nil, onClose: @escaping () -> Void) {
        self.puzzle = puzzle
        self.difficulty = difficulty
        self.size = size
        self.title = title
        self.subtitle = subtitle
        self.puzzleID = puzzleID
        self.isDaily = isDaily
        self.dailyKey = dailyKey
        self.onNext = onNext
        self.onClose = onClose
        _session = StateObject(wrappedValue: BoardSession(puzzle: puzzle, difficulty: difficulty,
                                                          size: size, saved: saved))
    }

    var body: some View {
        ZStack {
            WaterBackground()
            VStack(spacing: 0) {
                header
                boardArea
                statusBar
                controls
            }
            if let msg = hintMessage { hintBanner(msg) }
            if showSolved { solvedOverlay }
        }
        .navigationBarHidden(true)
        .onReceive(timer) { _ in
            if !showSolved && !session.solved { session.tick() }
        }
        .onChange(of: session.solved) { solved in
            if solved && !showSolved { handleSolved() }
        }
        .onChange(of: session.values) { _ in persist() }
        .onDisappear { persist() }
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .center) {
            BackButton { persist(); onClose() }
            Spacer()
            VStack(spacing: 1) {
                Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(Palette.ink)
                Text(subtitle).font(.system(size: 11, weight: .medium)).foregroundColor(Palette.inkSoft)
            }
            Spacer()
            DifficultyPill(difficulty: difficulty, compact: true)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    // MARK: Board

    private var boardArea: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Palette.waterDeep.opacity(0.10))
                    .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(session.illegalFlash ? Palette.danger : Palette.cardEdge,
                                lineWidth: session.illegalFlash ? 3 : 1))
                BoardView(session: session,
                          screenSize: geo.size,
                          showRemaining: store.settings.showRemaining,
                          colorblind: store.settings.colorblindMarker,
                          hintEdge: hintEdge)
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(.horizontal, 12)
    }

    // MARK: Status

    private var statusBar: some View {
        HStack(spacing: 14) {
            statusChip(title: "Time", value: formatTime(session.elapsed))
            statusChip(title: "Islands", value: "\(session.satisfiedCount)/\(session.islandCount)")
            HStack(spacing: 6) {
                Circle()
                    .fill(connectivityColor)
                    .frame(width: 9, height: 9)
                Text(connectivityText)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Palette.ink)
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(Capsule().fill(Palette.card))
            .overlay(Capsule().stroke(Palette.cardEdge, lineWidth: 1))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private func statusChip(title: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(title).font(.system(size: 11, weight: .semibold)).foregroundColor(Palette.inkSoft)
            Text(value).font(.system(size: 13, weight: .heavy)).foregroundColor(Palette.ink)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Capsule().fill(Palette.card))
        .overlay(Capsule().stroke(Palette.cardEdge, lineWidth: 1))
    }

    private var connectivityColor: Color {
        if !session.hasAnyBridge { return Palette.cardEdge }
        return session.componentCount() == 1 ? Palette.satisfied : Palette.coral
    }
    private var connectivityText: String {
        if !session.hasAnyBridge { return "Empty" }
        let c = session.componentCount()
        return c == 1 ? "Linked" : "\(c) groups"
    }

    // MARK: Controls

    private var controls: some View {
        HStack(spacing: 0) {
            GlyphButton(glyph: UndoGlyph(), label: "Undo", disabled: !session.canUndo) {
                session.undo()
            }.frame(maxWidth: .infinity)
            GlyphButton(glyph: RestartGlyph(), label: "Restart") {
                if store.settings.confirmActions { confirmRestart = true } else { session.restart() }
            }.frame(maxWidth: .infinity)
            GlyphButton(glyph: ShieldGlyph(), label: "Check", tint: Palette.waterDeep) {
                runCheck()
            }.frame(maxWidth: .infinity)
            GlyphButton(glyph: SparkFill(), label: "Hint", tint: Palette.coral) {
                useHint()
            }.frame(maxWidth: .infinity)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .padding(.horizontal, 8)
        .background(Palette.card.opacity(0.6).edgesIgnoringSafeArea(.bottom))
        .alert(isPresented: $confirmRestart) {
            Alert(title: Text("Restart puzzle?"),
                  message: Text("This clears all bridges you've placed."),
                  primaryButton: .destructive(Text("Restart")) { session.restart() },
                  secondaryButton: .cancel())
        }
    }

    // MARK: Hint banner

    private func hintBanner(_ msg: String) -> some View {
        VStack {
            Spacer()
            HStack(alignment: .top, spacing: 10) {
                SparkFill().fill(Palette.coral).frame(width: 18, height: 18)
                Text(msg).font(.system(size: 13, weight: .semibold)).foregroundColor(Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(Palette.card)
                .shadow(color: Palette.ink.opacity(0.12), radius: 8, y: 3))
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.coral.opacity(0.4), lineWidth: 1))
            .padding(.horizontal, 16)
            .padding(.bottom, 96)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: Solved overlay

    private var solvedOverlay: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
                .onTapGesture {}
            VStack(spacing: 18) {
                Text("Solved!")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(Palette.ink)
                StarRow(filled: awardedStars, total: 3, size: 30)
                VStack(spacing: 4) {
                    Text("Time  \(formatTime(session.elapsed))")
                        .font(.system(size: 15, weight: .bold)).foregroundColor(Palette.ink)
                    Text(starBlurb).font(.system(size: 12, weight: .medium)).foregroundColor(Palette.inkSoft)
                }
                VStack(spacing: 10) {
                    if let next = onNext {
                        PrimaryButton(title: "Next Puzzle", fill: Palette.waterDeep) {
                            persist(); next()
                        }
                    }
                    PrimaryButton(title: "Replay", fill: Palette.sandDeep) {
                        showSolved = false
                        session.restart()
                    }
                    PrimaryButton(title: "Back", fill: Palette.coral) {
                        persist(); onClose()
                    }
                }
            }
            .padding(26)
            .frame(maxWidth: 320)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Palette.card))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.cardEdge, lineWidth: 1))
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
    }

    private var starBlurb: String {
        switch awardedStars {
        case 3: return "Flawless — no hints, no errors."
        case 2: return "Nicely done. Aim for a clean solve next time."
        default: return "Solved! Try again with no hints or errors for 3 stars."
        }
    }

    // MARK: Actions

    private func handleSolved() {
        let stars = store.completePuzzle(id: puzzleID, difficulty: difficulty, size: size,
                                         seconds: session.elapsed,
                                         usedHint: session.usedHint, hadError: session.hadError,
                                         isDaily: isDaily, dailyKey: dailyKey)
        awardedStars = stars
        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) { showSolved = true }
        persist()
    }

    private func runCheck() {
        let hasErr = session.runCheck()
        store.pushToast(ToastItem(kind: hasErr ? .warn : .info,
                                  title: hasErr ? "Errors found" : "Looking good",
                                  message: hasErr ? "Highlighted bridges/islands need fixing."
                                                  : "No mistakes so far. Keep going!"))
    }

    private func useHint() {
        hintEdge = session.hintTargetEdge()
        if let msg = session.hint() {
            store.registerHintUsed()
            withAnimation { hintMessage = msg }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                withAnimation { if hintMessage == msg { hintMessage = nil } }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { hintEdge = nil }
            persist()
        } else {
            store.pushToast(ToastItem(kind: .info, title: "No hint",
                                      message: "Everything that can be deduced is already placed."))
        }
    }

    private func persist() {
        if isDaily, let key = dailyKey {
            store.saveDailyProgress(key: key, bridges: session.values, elapsed: session.elapsed,
                                    hadError: session.hadError, usedHint: session.usedHint)
        } else {
            store.saveProgress(id: puzzleID, bridges: session.values, elapsed: session.elapsed,
                               hadError: session.hadError, usedHint: session.usedHint)
        }
    }
}
