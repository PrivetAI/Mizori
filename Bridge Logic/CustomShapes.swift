import SwiftUI

// All iconography is hand-drawn with Shape/Path — no SF Symbols, no emoji.

// MARK: - Star

struct StarShape: Shape {
    var points: Int = 5
    var innerRatio: CGFloat = 0.45

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let inner = r * innerRatio
        let steps = points * 2
        for i in 0..<steps {
            let angle = -CGFloat.pi / 2 + CGFloat(i) * .pi / CGFloat(points)
            let rad = i.isMultiple(of: 2) ? r : inner
            let pt = CGPoint(x: c.x + cos(angle) * rad, y: c.y + sin(angle) * rad)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Check / warn / close

struct CheckGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.15, y: h * 0.55))
        p.addLine(to: CGPoint(x: w * 0.42, y: h * 0.82))
        p.addLine(to: CGPoint(x: w * 0.88, y: h * 0.2))
        return p
    }
}

struct WarnGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.12))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.62))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.82))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.88))
        return p
    }
}

struct CloseGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.2, y: h * 0.2))
        p.addLine(to: CGPoint(x: w * 0.8, y: h * 0.8))
        p.move(to: CGPoint(x: w * 0.8, y: h * 0.2))
        p.addLine(to: CGPoint(x: w * 0.2, y: h * 0.8))
        return p
    }
}

// MARK: - Chevron

struct ChevronGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.35, y: h * 0.2))
        p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.5))
        p.addLine(to: CGPoint(x: w * 0.35, y: h * 0.8))
        return p
    }
}

// MARK: - Compass (Play / Daily theming)

struct CompassGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        // needle
        p.move(to: CGPoint(x: c.x, y: c.y - r * 0.55))
        p.addLine(to: CGPoint(x: c.x + r * 0.32, y: c.y))
        p.addLine(to: CGPoint(x: c.x, y: c.y + r * 0.55))
        p.addLine(to: CGPoint(x: c.x - r * 0.32, y: c.y))
        p.closeSubpath()
        return p
    }
}

// MARK: - Island disc + bridge marks (used as glyphs and brand)

struct IslandGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        return p
    }
}

struct BridgeGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // two islands + a double plank between
        let r = h * 0.22
        p.addEllipse(in: CGRect(x: 0, y: h * 0.5 - r, width: r * 2, height: r * 2))
        p.addEllipse(in: CGRect(x: w - r * 2, y: h * 0.5 - r, width: r * 2, height: r * 2))
        p.move(to: CGPoint(x: r * 2, y: h * 0.5 - h * 0.12))
        p.addLine(to: CGPoint(x: w - r * 2, y: h * 0.5 - h * 0.12))
        p.move(to: CGPoint(x: r * 2, y: h * 0.5 + h * 0.12))
        p.addLine(to: CGPoint(x: w - r * 2, y: h * 0.5 + h * 0.12))
        return p
    }
}

// MARK: - Lock

struct LockGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let bodyRect = CGRect(x: w * 0.2, y: h * 0.45, width: w * 0.6, height: h * 0.42)
        p.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: 4, height: 4))
        // shackle
        let r = w * 0.18
        p.addArc(center: CGPoint(x: w * 0.5, y: h * 0.45),
                 radius: r, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
        p.move(to: CGPoint(x: w * 0.5 - r, y: h * 0.45))
        p.addLine(to: CGPoint(x: w * 0.5 - r, y: h * 0.35))
        p.move(to: CGPoint(x: w * 0.5 + r, y: h * 0.45))
        p.addLine(to: CGPoint(x: w * 0.5 + r, y: h * 0.35))
        return p
    }
}

// MARK: - Undo / restart

struct UndoGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) * 0.34
        p.addArc(center: c, radius: r, startAngle: .degrees(120), endAngle: .degrees(380), clockwise: false)
        // arrow head at start (120°)
        let a = CGFloat.pi * 120 / 180
        let tip = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
        p.move(to: tip)
        p.addLine(to: CGPoint(x: tip.x - r * 0.5, y: tip.y - r * 0.05))
        p.move(to: tip)
        p.addLine(to: CGPoint(x: tip.x - r * 0.1, y: tip.y + r * 0.5))
        return p
    }
}

struct RestartGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) * 0.34
        p.addArc(center: c, radius: r, startAngle: .degrees(-60), endAngle: .degrees(220), clockwise: false)
        let a = CGFloat.pi * -60 / 180
        let tip = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
        p.move(to: tip)
        p.addLine(to: CGPoint(x: tip.x - r * 0.5, y: tip.y - r * 0.1))
        p.move(to: tip)
        p.addLine(to: CGPoint(x: tip.x + r * 0.05, y: tip.y - r * 0.5))
        return p
    }
}

// MARK: - Hint spark

struct HintSparkGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        // four-point sparkle
        for i in 0..<4 {
            let a = CGFloat(i) * .pi / 2
            let outer = CGPoint(x: c.x + cos(a) * r, y: c.y + sin(a) * r)
            let leftA = a + .pi * 0.18
            let rightA = a - .pi * 0.18
            let mid = r * 0.32
            let l = CGPoint(x: c.x + cos(leftA) * mid, y: c.y + sin(leftA) * mid)
            let rr = CGPoint(x: c.x + cos(rightA) * mid, y: c.y + sin(rightA) * mid)
            if i == 0 { p.move(to: outer) } else { p.addLine(to: outer) }
            p.addLine(to: l)
            p.move(to: outer)
            p.addLine(to: rr)
        }
        return p
    }
}

struct SparkFill: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        let inner = r * 0.34
        for i in 0..<8 {
            let a = -CGFloat.pi / 2 + CGFloat(i) * .pi / 4
            let rad = i.isMultiple(of: 2) ? r : inner
            let pt = CGPoint(x: c.x + cos(a) * rad, y: c.y + sin(a) * rad)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Tab bar glyphs

struct PlayTabGlyph: Shape {  // map/compass for Play
    func path(in rect: CGRect) -> Path {
        CompassGlyph().path(in: rect)
    }
}

struct DailyTabGlyph: Shape { // sun rising over water
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let c = CGPoint(x: w * 0.5, y: h * 0.62)
        let r = w * 0.22
        p.addArc(center: c, radius: r, startAngle: .degrees(180), endAngle: .degrees(360), clockwise: false)
        p.move(to: CGPoint(x: w * 0.1, y: h * 0.62))
        p.addLine(to: CGPoint(x: w * 0.9, y: h * 0.62))
        // rays
        for i in 0..<3 {
            let a = CGFloat.pi + CGFloat(i + 1) * .pi / 4
            let s = CGPoint(x: c.x + cos(a) * (r + w * 0.04), y: c.y + sin(a) * (r + w * 0.04))
            let e = CGPoint(x: c.x + cos(a) * (r + w * 0.16), y: c.y + sin(a) * (r + w * 0.16))
            p.move(to: s); p.addLine(to: e)
        }
        return p
    }
}

struct AwardsTabGlyph: Shape { // medal/trophy
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let c = CGPoint(x: w * 0.5, y: h * 0.42)
        let r = w * 0.26
        p.addEllipse(in: CGRect(x: c.x - r, y: c.y - r, width: r * 2, height: r * 2))
        // ribbon
        p.move(to: CGPoint(x: c.x - r * 0.55, y: c.y + r * 0.7))
        p.addLine(to: CGPoint(x: c.x - r * 0.3, y: h * 0.92))
        p.addLine(to: CGPoint(x: c.x, y: h * 0.78))
        p.addLine(to: CGPoint(x: c.x + r * 0.3, y: h * 0.92))
        p.addLine(to: CGPoint(x: c.x + r * 0.55, y: c.y + r * 0.7))
        return p
    }
}

struct MoreTabGlyph: Shape { // book/scroll
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.addRoundedRect(in: CGRect(x: w * 0.2, y: h * 0.18, width: w * 0.6, height: h * 0.64),
                         cornerSize: CGSize(width: 3, height: 3))
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.18))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.82))
        p.move(to: CGPoint(x: w * 0.3, y: h * 0.36))
        p.addLine(to: CGPoint(x: w * 0.44, y: h * 0.36))
        p.move(to: CGPoint(x: w * 0.56, y: h * 0.36))
        p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.36))
        return p
    }
}

struct GearGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) * 0.32
        let teeth = 8
        let outer = r * 1.35
        for i in 0..<(teeth * 2) {
            let a = CGFloat(i) * .pi / CGFloat(teeth)
            let rad = i.isMultiple(of: 2) ? outer : r
            let pt = CGPoint(x: c.x + cos(a) * rad, y: c.y + sin(a) * rad)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        p.addEllipse(in: CGRect(x: c.x - r * 0.4, y: c.y - r * 0.4, width: r * 0.8, height: r * 0.8))
        return p
    }
}

struct BookGlyph: Shape {
    func path(in rect: CGRect) -> Path { MoreTabGlyph().path(in: rect) }
}

struct ShieldGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: w * 0.5, y: h * 0.12))
        p.addLine(to: CGPoint(x: w * 0.85, y: h * 0.26))
        p.addLine(to: CGPoint(x: w * 0.85, y: h * 0.55))
        p.addQuadCurve(to: CGPoint(x: w * 0.5, y: h * 0.9),
                       control: CGPoint(x: w * 0.8, y: h * 0.82))
        p.addQuadCurve(to: CGPoint(x: w * 0.15, y: h * 0.55),
                       control: CGPoint(x: w * 0.2, y: h * 0.82))
        p.addLine(to: CGPoint(x: w * 0.15, y: h * 0.26))
        p.closeSubpath()
        return p
    }
}

// MARK: - Small reusable star row

struct StarRow: View {
    let filled: Int
    let total: Int
    var size: CGFloat = 14
    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<total, id: \.self) { i in
                StarShape(points: 5)
                    .fill(i < filled ? Palette.star : Palette.cardEdge)
                    .frame(width: size, height: size)
            }
        }
    }
}
