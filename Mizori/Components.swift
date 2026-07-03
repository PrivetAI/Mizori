import SwiftUI

/// Soft water-gradient background used app-wide.
struct WaterBackground: View {
    var body: some View {
        LinearGradient(colors: [Palette.water, Color(red: 0.78, green: 0.90, blue: 0.90)],
                       startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()
    }
}

struct ScreenTitle: View {
    let title: String
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .foregroundColor(Palette.ink)
            if let s = subtitle {
                Text(s).font(.system(size: 14, weight: .medium)).foregroundColor(Palette.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DifficultyPill: View {
    let difficulty: HashiDifficulty
    var compact: Bool = false
    var body: some View {
        Text(difficulty.title.uppercased())
            .font(.system(size: compact ? 10 : 11, weight: .heavy))
            .tracking(0.5)
            .foregroundColor(.white)
            .padding(.horizontal, compact ? 8 : 10)
            .padding(.vertical, compact ? 3 : 5)
            .background(Capsule().fill(Palette.difficultyColor(difficulty)))
    }
}

/// Primary filled action button.
struct PrimaryButton: View {
    let title: String
    var fill: Color = Palette.waterDeep
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(fill))
        }
        .buttonStyle(.plain)
    }
}

/// A round control button with a custom glyph (board HUD + nav).
struct GlyphButton<G: Shape>: View {
    let glyph: G
    let label: String
    var tint: Color = Palette.ink
    var bg: Color = Palette.card
    var filled: Bool = false
    var disabled: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                ZStack {
                    Circle()
                        .fill(filled ? tint : bg)
                        .frame(width: 50, height: 50)
                        .overlay(Circle().stroke(Palette.cardEdge, lineWidth: filled ? 0 : 1))
                    glyph
                        .stroke(filled ? Color.white : tint,
                                style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
                        .frame(width: 22, height: 22)
                }
                Text(label).font(.system(size: 11, weight: .semibold))
                    .foregroundColor(disabled ? Palette.inkSoft : Palette.ink)
            }
            .opacity(disabled ? 0.4 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

/// Back chevron button for nested screens.
struct BackButton: View {
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                ChevronGlyph()
                    .stroke(Palette.ink, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 14, height: 14)
                    .rotationEffect(.degrees(180))
                Text("Back").font(.system(size: 15, weight: .semibold)).foregroundColor(Palette.ink)
            }
            .padding(.vertical, 6).padding(.horizontal, 4)
        }
        .buttonStyle(.plain)
    }
}

/// A labelled toggle row matching the theme (no system Toggle styling mizori).
struct ZenToggle: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { isOn.toggle() }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.system(size: 15, weight: .bold)).foregroundColor(Palette.ink)
                    Text(detail).font(.system(size: 12, weight: .medium)).foregroundColor(Palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 8)
                ZStack {
                    Capsule()
                        .fill(isOn ? Palette.satisfied : Palette.cardEdge)
                        .frame(width: 46, height: 28)
                    Circle().fill(.white).frame(width: 22, height: 22)
                        .offset(x: isOn ? 9 : -9)
                        .shadow(color: Palette.ink.opacity(0.15), radius: 2, y: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

func formatTime(_ seconds: Int) -> String {
    let m = seconds / 60, s = seconds % 60
    return String(format: "%d:%02d", m, s)
}
