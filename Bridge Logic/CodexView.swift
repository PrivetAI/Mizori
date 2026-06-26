import SwiftUI

/// A tiny static diagram of a Hashi configuration used to illustrate rules
/// and techniques in the codex.
struct MiniDiagram: View {
    struct Node { let r: Int; let c: Int; let n: Int; let satisfied: Bool }
    struct Link { let ar: Int; let ac: Int; let br: Int; let bc: Int; let count: Int; let ghost: Bool }
    let cols: Int
    let rows: Int
    let nodes: [Node]
    let links: [Link]

    var body: some View {
        Canvas { ctx, size in
            let step = min(size.width / CGFloat(cols), size.height / CGFloat(rows))
            let ox = (size.width - step * CGFloat(cols)) / 2
            let oy = (size.height - step * CGFloat(rows)) / 2
            func pt(_ r: Int, _ c: Int) -> CGPoint {
                CGPoint(x: ox + (CGFloat(c) + 0.5) * step, y: oy + (CGFloat(r) + 0.5) * step)
            }
            for l in links {
                let a = pt(l.ar, l.ac), b = pt(l.br, l.bc)
                let horiz = l.ar == l.br
                let color = l.ghost ? Palette.coral.opacity(0.5) : Palette.driftwood
                let style = l.ghost
                    ? StrokeStyle(lineWidth: 3, lineCap: .round, dash: [4, 4])
                    : StrokeStyle(lineWidth: 3, lineCap: .round)
                if l.count <= 1 {
                    var p = Path(); p.move(to: a); p.addLine(to: b)
                    ctx.stroke(p, with: .color(color), style: style)
                } else {
                    let off: CGFloat = 3.5
                    for s in [-1.0, 1.0] {
                        var p = Path()
                        if horiz {
                            p.move(to: CGPoint(x: a.x, y: a.y + off * s)); p.addLine(to: CGPoint(x: b.x, y: b.y + off * s))
                        } else {
                            p.move(to: CGPoint(x: a.x + off * s, y: a.y)); p.addLine(to: CGPoint(x: b.x + off * s, y: b.y))
                        }
                        ctx.stroke(p, with: .color(color), style: style)
                    }
                }
            }
            let rad = step * 0.34
            for nd in nodes {
                let c = pt(nd.r, nd.c)
                let rect = CGRect(x: c.x - rad, y: c.y - rad, width: rad * 2, height: rad * 2)
                ctx.fill(Path(ellipseIn: rect), with: .color(nd.satisfied ? Palette.satisfied : Palette.sand))
                ctx.stroke(Path(ellipseIn: rect), with: .color(nd.satisfied ? Palette.satisfied : Palette.sandDeep), lineWidth: 1.5)
                let t = ctx.resolve(Text("\(nd.n)").font(.system(size: rad * 1.1, weight: .heavy))
                    .foregroundColor(nd.satisfied ? .white : Palette.ink))
                ctx.draw(t, at: c)
            }
        }
        .frame(height: 90)
    }
}

struct CodexView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            WaterBackground()
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        BackButton { presentationMode.wrappedValue.dismiss() }
                        Spacer()
                    }
                    ScreenTitle(title: "How to Play", subtitle: "Bridges, rules & deduction")

                    rulesCard
                    controlsCard
                    techniquesHeader
                    techCard(
                        title: "Full island",
                        text: "An island whose number equals the maximum bridges its open channels can hold must use them all. A “4” with exactly two neighbours takes a double bridge to each.",
                        diagram: MiniDiagram(cols: 3, rows: 1,
                            nodes: [.init(r: 0, c: 0, n: 2, satisfied: true),
                                    .init(r: 0, c: 1, n: 4, satisfied: true),
                                    .init(r: 0, c: 2, n: 2, satisfied: true)],
                            links: [.init(ar: 0, ac: 0, br: 0, bc: 1, count: 2, ghost: false),
                                    .init(ar: 0, ac: 1, br: 0, bc: 2, count: 2, ghost: false)]))
                    techCard(
                        title: "Forced single",
                        text: "If an island still needs a bridge and only one channel remains open, a bridge must run there — even before you know if it becomes a double.",
                        diagram: MiniDiagram(cols: 3, rows: 1,
                            nodes: [.init(r: 0, c: 0, n: 1, satisfied: false),
                                    .init(r: 0, c: 2, n: 1, satisfied: false)],
                            links: [.init(ar: 0, ac: 0, br: 0, bc: 2, count: 1, ghost: true)]))
                    techCard(
                        title: "No crossing",
                        text: "Bridges never cross. If a horizontal bridge is forced, every vertical channel passing through it is ruled out — and vice-versa.",
                        diagram: MiniDiagram(cols: 3, rows: 3,
                            nodes: [.init(r: 1, c: 0, n: 2, satisfied: true),
                                    .init(r: 1, c: 2, n: 2, satisfied: true),
                                    .init(r: 0, c: 1, n: 1, satisfied: false),
                                    .init(r: 2, c: 1, n: 1, satisfied: false)],
                            links: [.init(ar: 1, ac: 0, br: 1, bc: 2, count: 2, ghost: false),
                                    .init(ar: 0, ac: 1, br: 2, bc: 1, count: 1, ghost: true)]))
                    techCard(
                        title: "Isolation / connectivity",
                        text: "Every island must end in ONE network. Avoid a move that would seal off a small group from the rest — even if its numbers look satisfied. Use this to break ties the counting rules leave open.",
                        diagram: MiniDiagram(cols: 4, rows: 1,
                            nodes: [.init(r: 0, c: 0, n: 1, satisfied: true),
                                    .init(r: 0, c: 1, n: 2, satisfied: true),
                                    .init(r: 0, c: 2, n: 2, satisfied: true),
                                    .init(r: 0, c: 3, n: 1, satisfied: true)],
                            links: [.init(ar: 0, ac: 0, br: 0, bc: 1, count: 1, ghost: false),
                                    .init(ar: 0, ac: 1, br: 0, bc: 2, count: 1, ghost: false),
                                    .init(ar: 0, ac: 2, br: 0, bc: 3, count: 1, ghost: false)]))
                    techCard(
                        title: "What-if elimination",
                        text: "When pure counting stalls (Hard & Expert), assume a channel takes a value and follow the consequences. If it forces a contradiction, the other value is correct. The Hint button uses exactly this engine.",
                        diagram: nil)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
        }
        .navigationBarHidden(true)
    }

    private var rulesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("The rules").font(.system(size: 16, weight: .bold)).foregroundColor(Palette.ink)
            bullet("Connect islands with horizontal or vertical bridges.")
            bullet("Each island’s number = the count of bridge-ends touching it.")
            bullet("At most TWO bridges between any pair of islands.")
            bullet("Bridges never cross and never pass through an island.")
            bullet("When finished, all islands form a single connected network.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zenCard()
    }

    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Controls").font(.system(size: 16, weight: .bold)).foregroundColor(Palette.ink)
            bullet("Tap one island, then a second in line to add a bridge.")
            bullet("Or drag from one island to another.")
            bullet("Tapping the same pair cycles: none → single → double → none.")
            bullet("Pinch to zoom and drag the water to pan on large grids.")
            bullet("Undo, Restart, Check for mistakes, or take a Hint anytime.")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zenCard()
    }

    private var techniquesHeader: some View {
        Text("Deduction techniques")
            .font(.system(size: 18, weight: .black, design: .rounded))
            .foregroundColor(Palette.ink)
            .padding(.top, 4)
    }

    private func techCard(title: String, text: String, diagram: MiniDiagram?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(Palette.waterDeep)
            if let d = diagram {
                d.background(RoundedRectangle(cornerRadius: 10).fill(Palette.waterDeep.opacity(0.07)))
            }
            Text(text).font(.system(size: 13, weight: .medium)).foregroundColor(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .zenCard()
    }

    private func bullet(_ s: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(Palette.coral).frame(width: 6, height: 6).padding(.top, 6)
            Text(s).font(.system(size: 13, weight: .medium)).foregroundColor(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
