import SwiftUI

/// Renders the island grid + mizoris with a Canvas. Camera math is anchored to
/// the parent-passed `screenSize` (from an outer GeometryReader), never the
/// Canvas closure's `size`, per the documented iOS Canvas pitfall.
struct BoardView: View {
    @ObservedObject var session: BoardSession
    let screenSize: CGSize
    let showRemaining: Bool
    let colorblind: Bool
    var hintEdge: Int? = nil

    @State private var zoom: CGFloat = 1
    @State private var liveZoom: CGFloat = 1
    @State private var pan: CGSize = .zero
    @State private var panStart: CGSize = .zero

    private enum DragMode { case none, pan, mizori(Int) }
    @State private var dragMode: DragMode = .none
    @State private var mizoriDragFrom: Int? = nil
    @State private var mizoriDragTo: CGPoint? = nil

    private var gridW: Int { session.puzzle.width }
    private var gridH: Int { session.puzzle.height }

    private var cell0: CGFloat {
        max(8, min(screenSize.width / CGFloat(gridW), screenSize.height / CGFloat(gridH)))
    }
    private var effectiveZoom: CGFloat { zoom * liveZoom }

    private var boardW: CGFloat { cell0 * CGFloat(gridW) * effectiveZoom }
    private var boardH: CGFloat { cell0 * CGFloat(gridH) * effectiveZoom }
    private var originX: CGFloat { (screenSize.width - boardW) / 2 + pan.width }
    private var originY: CGFloat { (screenSize.height - boardH) / 2 + pan.height }

    private func center(of island: Int) -> CGPoint {
        let cl = session.puzzle.clues[island]
        let step = cell0 * effectiveZoom
        return CGPoint(x: originX + (CGFloat(cl.c) + 0.5) * step,
                       y: originY + (CGFloat(cl.r) + 0.5) * step)
    }

    private func island(at p: CGPoint) -> Int? {
        let step = cell0 * effectiveZoom
        let radius = step * 0.5
        var best = -1
        var bestDist = radius * radius
        for i in 0..<session.puzzle.clues.count {
            let c = center(of: i)
            let dx = c.x - p.x, dy = c.y - p.y
            let d = dx * dx + dy * dy
            if d < bestDist { bestDist = d; best = i }
        }
        return best >= 0 ? best : nil
    }

    var body: some View {
        Canvas { ctx, _ in
            draw(ctx)
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .simultaneousGesture(magnify)
        .onChange(of: session.solved) { _ in }
    }

    // MARK: Drawing

    private func draw(_ ctx: GraphicsContext) {
        let step = cell0 * effectiveZoom
        let islRadius = step * 0.40

        // Faint grid wash so mizoris read clearly.
        var dots = Path()
        for r in 0..<gridH {
            for c in 0..<gridW {
                let x = originX + (CGFloat(c) + 0.5) * step
                let y = originY + (CGFloat(r) + 0.5) * step
                dots.addEllipse(in: CGRect(x: x - 1, y: y - 1, width: 2, height: 2))
            }
        }
        ctx.fill(dots, with: .color(Palette.waterDeep.opacity(0.08)))

        // Mizoris.
        for (i, e) in session.graph.edges.enumerated() {
            let v = session.values[i]
            guard v >= 1 else { continue }
            let a = center(of: e.a)
            let b = center(of: e.b)
            let isError = session.errorEdges.contains(i)
            let color = isError ? Palette.danger : Palette.mizoriwood
            let lw = max(2.2, step * 0.07)
            if v == 1 {
                var p = Path(); p.move(to: a); p.addLine(to: b)
                ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: lw, lineCap: .round))
            } else {
                let off = max(2.5, step * 0.10)
                let (ox, oy) = e.horizontal ? (CGFloat(0), off) : (off, CGFloat(0))
                for s in [-1.0, 1.0] {
                    var p = Path()
                    p.move(to: CGPoint(x: a.x + ox * s, y: a.y + oy * s))
                    p.addLine(to: CGPoint(x: b.x + ox * s, y: b.y + oy * s))
                    ctx.stroke(p, with: .color(color), style: StrokeStyle(lineWidth: lw, lineCap: .round))
                }
            }
        }

        // Live mizori-drag ghost.
        if let from = mizoriDragFrom, let to = mizoriDragTo {
            var p = Path(); p.move(to: center(of: from)); p.addLine(to: to)
            ctx.stroke(p, with: .color(Palette.coral.opacity(0.6)),
                       style: StrokeStyle(lineWidth: max(2, step * 0.06), lineCap: .round, dash: [6, 6]))
        }

        // Islands.
        for i in 0..<session.puzzle.clues.count {
            let c = center(of: i)
            let rect = CGRect(x: c.x - islRadius, y: c.y - islRadius,
                              width: islRadius * 2, height: islRadius * 2)
            let satisfied = session.isSatisfied(i)
            let over = session.isOver(i) || session.errorIslands.contains(i)

            // shadow ring
            ctx.fill(Path(ellipseIn: rect.insetBy(dx: -2, dy: -2)),
                     with: .color(Palette.waterDeep.opacity(0.18)))

            let fill: Color = over ? Palette.danger.opacity(0.85)
                : (satisfied ? Palette.satisfied : Palette.sand)
            ctx.fill(Path(ellipseIn: rect), with: .color(fill))

            let ringColor = (session.selected == i) ? Palette.coral
                : (i == hintEdgeIsland ? Palette.star : Palette.sandDeep)
            let ringW: CGFloat = (session.selected == i || i == hintEdgeIsland) ? 3 : 1.6
            ctx.stroke(Path(ellipseIn: rect), with: .color(ringColor), lineWidth: ringW)

            // label
            let label: String
            if satisfied && colorblind {
                label = "✓-marker"
            } else if showRemaining && !satisfied {
                label = "\(session.remaining(of: i))"
            } else {
                label = "\(session.need(of: i))"
            }

            let fontSize = max(9, islRadius * 1.0)
            if satisfied && colorblind {
                // draw a check glyph instead of a number
                let g = islRadius
                var ck = Path()
                ck.move(to: CGPoint(x: c.x - g * 0.45, y: c.y))
                ck.addLine(to: CGPoint(x: c.x - g * 0.1, y: c.y + g * 0.4))
                ck.addLine(to: CGPoint(x: c.x + g * 0.5, y: c.y - g * 0.4))
                ctx.stroke(ck, with: .color(.white),
                           style: StrokeStyle(lineWidth: max(2, g * 0.22), lineCap: .round, lineJoin: .round))
            } else {
                let textColor: Color = (satisfied || over) ? .white : Palette.ink
                let resolved = ctx.resolve(
                    Text(label).font(.system(size: fontSize, weight: .heavy)).foregroundColor(textColor))
                ctx.draw(resolved, at: c)
            }
        }
    }

    private var hintEdgeIsland: Int? {
        guard let he = hintEdge, he < session.graph.edges.count else { return nil }
        return session.graph.edges[he].a
    }

    // MARK: Gestures

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { v in
                switch dragMode {
                case .none:
                    if let isl = island(at: v.startLocation) {
                        dragMode = .mizori(isl)
                        mizoriDragFrom = isl
                        mizoriDragTo = v.location
                    } else {
                        dragMode = .pan
                        panStart = pan
                    }
                case .pan:
                    pan = CGSize(width: panStart.width + v.translation.width,
                                 height: panStart.height + v.translation.height)
                case .mizori:
                    mizoriDragTo = v.location
                }
            }
            .onEnded { v in
                switch dragMode {
                case .mizori(let a):
                    let dist = hypot(v.translation.width, v.translation.height)
                    if dist < 12 {
                        session.tapIsland(a)
                    } else if let b = island(at: v.location), b != a {
                        _ = session.connect(a, b)
                        session.clearSelection()
                    }
                case .pan:
                    clampPan()
                default: break
                }
                dragMode = .none
                mizoriDragFrom = nil
                mizoriDragTo = nil
            }
    }

    private var magnify: some Gesture {
        MagnificationGesture()
            .onChanged { scale in
                liveZoom = scale
            }
            .onEnded { scale in
                zoom = min(3.0, max(1.0, zoom * scale))
                liveZoom = 1
                clampPan()
            }
    }

    private func clampPan() {
        // Keep the board from sliding entirely off-screen.
        let maxX = max(0, (boardW - screenSize.width) / 2 + cell0)
        let maxY = max(0, (boardH - screenSize.height) / 2 + cell0)
        pan.width = min(maxX, max(-maxX, pan.width))
        pan.height = min(maxY, max(-maxY, pan.height))
    }
}
