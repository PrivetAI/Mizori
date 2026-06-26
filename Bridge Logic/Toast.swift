import SwiftUI

struct ToastItem: Identifiable, Equatable {
    enum Kind { case success, award, info, warn }
    let id = UUID()
    let kind: Kind
    let title: String
    let message: String
}

struct ToastLayer: View {
    @ObservedObject var store: DataStore

    var body: some View {
        VStack(spacing: 8) {
            ForEach(store.toasts) { toast in
                ToastView(item: toast)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .allowsHitTesting(false)
    }
}

private struct ToastView: View {
    let item: ToastItem

    private var accent: Color {
        switch item.kind {
        case .success: return Palette.satisfied
        case .award: return Palette.star
        case .info: return Palette.waterDeep
        case .warn: return Palette.danger
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(accent.opacity(0.18)).frame(width: 38, height: 38)
                Group {
                    switch item.kind {
                    case .success: CheckGlyph().stroke(accent, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    case .award: StarShape(points: 5).fill(accent)
                    case .info: CompassGlyph().stroke(accent, lineWidth: 2)
                    case .warn: WarnGlyph().stroke(accent, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                    }
                }
                .frame(width: 20, height: 20)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title).font(.system(size: 13, weight: .bold)).foregroundColor(Palette.ink)
                Text(item.message).font(.system(size: 12, weight: .medium)).foregroundColor(Palette.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14).padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Palette.card)
                .shadow(color: Palette.ink.opacity(0.12), radius: 10, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(accent.opacity(0.4), lineWidth: 1)
        )
    }
}
