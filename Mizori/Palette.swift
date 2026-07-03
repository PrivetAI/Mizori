import SwiftUI

/// Calm zen archipelago palette. The app forces light mode and uses only
/// these colors so it looks identical regardless of device theme.
enum Palette {
    static let water       = Color(red: 0.863, green: 0.937, blue: 0.937) // #DCEFEF soft background
    static let waterDeep   = Color(red: 0.180, green: 0.541, blue: 0.541) // #2E8A8A
    static let waterDeep2  = Color(red: 0.129, green: 0.420, blue: 0.420) // darker teal
    static let sand        = Color(red: 0.910, green: 0.784, blue: 0.529) // #E8C887 island
    static let sandDeep    = Color(red: 0.831, green: 0.671, blue: 0.392) // island edge
    static let mizoriwood   = Color(red: 0.478, green: 0.353, blue: 0.235) // #7A5A3C mizori
    static let mizoriwood2  = Color(red: 0.380, green: 0.275, blue: 0.176) // mizori shadow
    static let ink         = Color(red: 0.149, green: 0.188, blue: 0.184) // #26302F text
    static let inkSoft     = Color(red: 0.149, green: 0.188, blue: 0.184).opacity(0.55)
    static let coral       = Color(red: 0.878, green: 0.475, blue: 0.353) // #E0795A accent
    static let coralDeep   = Color(red: 0.792, green: 0.376, blue: 0.259)
    static let card        = Color(red: 0.957, green: 0.984, blue: 0.984) // panels
    static let cardEdge    = Color(red: 0.722, green: 0.847, blue: 0.847)
    static let satisfied   = Color(red: 0.443, green: 0.722, blue: 0.612) // calm green
    static let star        = Color(red: 0.953, green: 0.776, blue: 0.353) // gold
    static let danger      = Color(red: 0.835, green: 0.341, blue: 0.310)

    static func difficultyColor(_ d: HashiDifficulty) -> Color {
        switch d {
        case .easy: return satisfied
        case .medium: return waterDeep
        case .hard: return coral
        case .expert: return coralDeep
        }
    }
}

extension View {
    /// Soft card container used throughout the UI.
    func zenCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(Palette.cardEdge, lineWidth: 1)
            )
    }
}
