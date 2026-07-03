import SwiftUI

// MARK: - Spinner (custom, no system assets)

struct ZenSpinner: View {
    @State private var spin = false
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.72)
            .stroke(Palette.waterDeep, style: StrokeStyle(lineWidth: 4, lineCap: .round))
            .frame(width: 34, height: 34)
            .rotationEffect(.degrees(spin ? 360 : 0))
            .animation(.linear(duration: 0.9).repeatForever(autoreverses: false), value: spin)
            .onAppear { spin = true }
    }
}

// MARK: - Pack list (Play tab root)

struct PlayView: View {
    @EnvironmentObject var store: DataStore

    var body: some View {
        ZStack {
            WaterBackground()
            ScrollView {
                VStack(spacing: 16) {
                    ScreenTitle(title: "Play", subtitle: "Connect every island into one network")
                        .padding(.top, 8)
                    ForEach(Array(PuzzleLibrary.packs.enumerated()), id: \.element.id) { idx, pack in
                        packRow(pack, index: idx)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
    }

    private func isUnlocked(_ index: Int) -> Bool {
        if index == 0 { return true }
        let prev = PuzzleLibrary.packs[index - 1]
        return store.packProgress(prev).solved >= 6
    }

    @ViewBuilder
    private func packRow(_ pack: PuzzlePack, index: Int) -> some View {
        let unlocked = isUnlocked(index)
        let prog = store.packProgress(pack)
        if unlocked {
            NavigationLink(destination: PackDetailView(pack: pack)) {
                packCard(pack, prog: prog, locked: false)
            }
            .buttonStyle(.plain)
        } else {
            packCard(pack, prog: prog, locked: true)
        }
    }

    private func packCard(_ pack: PuzzlePack, prog: (solved: Int, stars: Int), locked: Bool) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Palette.difficultyColor(pack.difficulty).opacity(locked ? 0.25 : 0.85))
                    .frame(width: 54, height: 54)
                if locked {
                    LockGlyph().stroke(Palette.waterDeep, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                        .frame(width: 24, height: 24)
                } else {
                    IslandGlyph().fill(.white.opacity(0.9)).frame(width: 22, height: 22)
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(pack.title).font(.system(size: 17, weight: .bold)).foregroundColor(Palette.ink)
                    DifficultyPill(difficulty: pack.difficulty, compact: true)
                }
                if locked {
                    Text("Solve 6 in the previous pack to unlock")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(Palette.inkSoft)
                } else {
                    Text("\(pack.subtitle) • \(pack.size.label)")
                        .font(.system(size: 12, weight: .medium)).foregroundColor(Palette.inkSoft)
                    HStack(spacing: 6) {
                        ProgressBar(value: Double(prog.solved) / Double(pack.count))
                            .frame(height: 6)
                        Text("\(prog.solved)/\(pack.count)")
                            .font(.system(size: 11, weight: .bold)).foregroundColor(Palette.inkSoft)
                    }
                }
            }
            if !locked {
                ChevronGlyph().stroke(Palette.inkSoft, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .frame(width: 12, height: 14)
            }
        }
        .zenCard()
        .opacity(locked ? 0.7 : 1)
    }
}

struct ProgressBar: View {
    let value: Double
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.cardEdge)
                Capsule().fill(Palette.satisfied)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
    }
}

// MARK: - Pack detail (puzzle list)

struct PackDetailView: View {
    @EnvironmentObject var store: DataStore
    let pack: PuzzlePack
    @Environment(\.presentationMode) private var presentationMode

    @State private var playingIndex: Int? = nil

    private let columns = [GridItem(.adaptive(minimum: 92), spacing: 12)]

    var body: some View {
        ZStack {
            WaterBackground()
            ScrollView {
                VStack(spacing: 16) {
                    ScreenTitle(title: pack.title, subtitle: "\(pack.subtitle) • \(pack.size.label) • \(pack.difficulty.title)")
                        .padding(.top, 8)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(0..<pack.count, id: \.self) { i in
                            puzzleTile(i)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 90)
            }
        }
        .navigationBarHidden(true)
        .fullScreenCover(isPresented: Binding(
            get: { playingIndex != nil },
            set: { if !$0 { playingIndex = nil } })) {
            if let idx = playingIndex {
                BoardLoaderView(
                    source: .pack(pack, idx),
                    onNext: idx + 1 < pack.count ? { playingIndex = idx + 1 } : nil,
                    onClose: { playingIndex = nil })
                    .environmentObject(store)
                    .id(idx)
            }
        }
    }

    private func puzzleTile(_ i: Int) -> some View {
        let rec = store.record(for: pack.puzzleID(for: i))
        let solved = rec?.solved ?? false
        let inProgress = (rec?.mizoris.contains { $0 > 0 }) ?? false
        return Button {
            playingIndex = i
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(solved ? Palette.satisfied.opacity(0.2) : Palette.card)
                        .frame(width: 46, height: 46)
                        .overlay(Circle().stroke(solved ? Palette.satisfied : Palette.cardEdge, lineWidth: 1.5))
                    Text("\(i + 1)").font(.system(size: 18, weight: .heavy)).foregroundColor(Palette.ink)
                }
                if solved {
                    StarRow(filled: rec?.stars ?? 0, total: 3, size: 9)
                } else if inProgress {
                    Text("in progress").font(.system(size: 9, weight: .bold)).foregroundColor(Palette.coral)
                } else {
                    Text("play").font(.system(size: 9, weight: .semibold)).foregroundColor(Palette.inkSoft)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .zenCard(padding: 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Async board loader

enum BoardSource {
    case pack(PuzzlePack, Int)
    case daily(Date)
}

struct BoardLoaderView: View {
    @EnvironmentObject var store: DataStore
    let source: BoardSource
    var onNext: (() -> Void)? = nil
    let onClose: () -> Void

    @State private var loaded: LoadedBoard? = nil

    struct LoadedBoard {
        let puzzle: HashiPuzzle
        let difficulty: HashiDifficulty
        let size: HashiGridSize
        let title: String
        let subtitle: String
        let id: String
        let isDaily: Bool
        let dailyKey: String?
        let saved: PuzzleRecord?
    }

    var body: some View {
        Group {
            if let lb = loaded {
                BoardScreen(puzzle: lb.puzzle, difficulty: lb.difficulty, size: lb.size,
                            title: lb.title, subtitle: lb.subtitle, puzzleID: lb.id,
                            isDaily: lb.isDaily, dailyKey: lb.dailyKey, saved: lb.saved,
                            onNext: onNext, onClose: onClose)
            } else {
                ZStack {
                    WaterBackground()
                    VStack(spacing: 16) {
                        ZenSpinner()
                        Text("Charting the islands…")
                            .font(.system(size: 14, weight: .semibold)).foregroundColor(Palette.inkSoft)
                    }
                }
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard loaded == nil else { return }
        switch source {
        case .pack(let pack, let idx):
            DispatchQueue.global(qos: .userInitiated).async {
                let puzzle = PuzzleLibrary.puzzle(pack: pack, index: idx)
                let id = pack.puzzleID(for: idx)
                let saved = store.record(for: id)
                let lb = LoadedBoard(puzzle: puzzle, difficulty: pack.difficulty, size: pack.size,
                                     title: pack.title, subtitle: "Puzzle \(idx + 1) of \(pack.count)",
                                     id: id, isDaily: false, dailyKey: nil, saved: saved)
                DispatchQueue.main.async { withAnimation { loaded = lb } }
            }
        case .daily(let date):
            DispatchQueue.global(qos: .userInitiated).async {
                let d = PuzzleLibrary.dailyPuzzle(for: date)
                let saved = store.dailyRecord(key: d.id)
                let lb = LoadedBoard(puzzle: d.puzzle, difficulty: d.difficulty, size: d.size,
                                     title: "Daily Puzzle", subtitle: d.id,
                                     id: "daily-\(d.id)", isDaily: true, dailyKey: d.id, saved: saved)
                DispatchQueue.main.async { withAnimation { loaded = lb } }
            }
        }
    }
}
