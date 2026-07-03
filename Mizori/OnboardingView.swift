import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: DataStore
    @State private var page = 0

    private struct Step {
        let title: String
        let body: String
    }
    private let steps: [Step] = [
        Step(title: "Welcome to Mizori",
             body: "A calm island puzzle of pure deduction. Build mizoris to link every island into one network — no luck, no guessing."),
        Step(title: "Read the numbers",
             body: "Each island’s number is how many mizori-ends must touch it. Mizoris run straight, horizontally or vertically, up to two between a pair."),
        Step(title: "Connect & deduce",
             body: "Tap two islands in line, or drag between them, to lay a mizori. Tap again to make it double, then to remove it. Mizoris may never cross."),
        Step(title: "Every puzzle is fair",
             body: "A solver proves every board has one logical solution. Stuck? Use Check or a Hint. Now — set sail and find your calm."),
    ]

    var body: some View {
        ZStack {
            WaterBackground()
            VStack(spacing: 24) {
                Spacer()
                diagram
                    .frame(height: 150)
                VStack(spacing: 12) {
                    Text(steps[page].title)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(Palette.ink)
                        .multilineTextAlignment(.center)
                    Text(steps[page].body)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Palette.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 28)
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { i in
                        Capsule()
                            .fill(i == page ? Palette.waterDeep : Palette.cardEdge)
                            .frame(width: i == page ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: page)
                    }
                }
                PrimaryButton(title: page == steps.count - 1 ? "Start Playing" : "Next") {
                    if page == steps.count - 1 {
                        store.completeOnboarding()
                    } else {
                        withAnimation(.easeInOut) { page += 1 }
                    }
                }
                .padding(.horizontal, 28)
                if page < steps.count - 1 {
                    Button("Skip") { store.completeOnboarding() }
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Palette.inkSoft)
                }
            }
            .padding(.bottom, 28)
        }
    }

    @ViewBuilder
    private var diagram: some View {
        switch page {
        case 0:
            MiniDiagram(cols: 3, rows: 3,
                nodes: [.init(r: 0, c: 0, n: 2, satisfied: true), .init(r: 0, c: 2, n: 3, satisfied: true),
                        .init(r: 2, c: 0, n: 1, satisfied: true), .init(r: 2, c: 2, n: 2, satisfied: true),
                        .init(r: 0, c: 1, n: 0, satisfied: false)],
                links: [.init(ar: 0, ac: 0, br: 0, bc: 2, count: 2, ghost: false),
                        .init(ar: 0, ac: 0, br: 2, bc: 0, count: 1, ghost: false),
                        .init(ar: 0, ac: 2, br: 2, bc: 2, count: 2, ghost: false)])
                .frame(height: 130)
        case 1:
            MiniDiagram(cols: 3, rows: 1,
                nodes: [.init(r: 0, c: 0, n: 2, satisfied: true), .init(r: 0, c: 1, n: 3, satisfied: false), .init(r: 0, c: 2, n: 1, satisfied: false)],
                links: [.init(ar: 0, ac: 0, br: 0, bc: 1, count: 2, ghost: false)])
        case 2:
            MiniDiagram(cols: 3, rows: 1,
                nodes: [.init(r: 0, c: 0, n: 1, satisfied: false), .init(r: 0, c: 2, n: 1, satisfied: false)],
                links: [.init(ar: 0, ac: 0, br: 0, bc: 2, count: 1, ghost: true)])
        default:
            MiniDiagram(cols: 3, rows: 3,
                nodes: [.init(r: 1, c: 0, n: 2, satisfied: true), .init(r: 1, c: 2, n: 2, satisfied: true),
                        .init(r: 0, c: 1, n: 1, satisfied: true), .init(r: 2, c: 1, n: 1, satisfied: true)],
                links: [.init(ar: 1, ac: 0, br: 1, bc: 2, count: 2, ghost: false),
                        .init(ar: 0, ac: 1, br: 2, bc: 1, count: 0, ghost: true)])
                .frame(height: 130)
        }
    }
}
