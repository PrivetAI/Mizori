import SwiftUI

struct MizoriLaunchScreen: View {
    @State private var glow = false

    var body: some View {
        ZStack {
            WaterBackground()
            VStack(spacing: 22) {
                ZStack {
                    Circle().fill(Palette.waterDeep.opacity(0.12)).frame(width: 128, height: 128)
                    MizoriGlyph()
                        .stroke(Palette.mizoriwood, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
                        .frame(width: 76, height: 50)
                }
                Text("Mizori")
                    .font(.system(size: 32, weight: .black, design: .rounded))
                    .foregroundColor(Palette.ink)
                Text("Linking the islands…")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Palette.inkSoft)
                HStack(spacing: 10) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(i.isMultiple(of: 2) ? Palette.waterDeep : Palette.coral)
                            .frame(width: 12, height: 12)
                            .scaleEffect(glow ? 1.4 : 0.7)
                            .animation(.easeInOut(duration: 0.7).repeatForever().delay(Double(i) * 0.12), value: glow)
                    }
                }
            }
        }
        .onAppear { glow = true }
    }
}
