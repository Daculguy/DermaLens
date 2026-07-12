import SwiftUI

enum Theme {
    static let background = Color(red: 0.965, green: 0.958, blue: 0.933)
    static let panel = Color(red: 0.996, green: 0.992, blue: 0.973)
    static let ink = Color(red: 0.094, green: 0.105, blue: 0.094)
    static let muted = Color(red: 0.443, green: 0.455, blue: 0.420)
    static let moss = Color(red: 0.133, green: 0.424, blue: 0.447)
    static let leaf = Color(red: 0.294, green: 0.510, blue: 0.341)
    static let coral = Color(red: 0.773, green: 0.337, blue: 0.282)
    static let amber = Color(red: 0.820, green: 0.592, blue: 0.243)
    static let lavender = Color(red: 0.521, green: 0.478, blue: 0.694)

    static let softShadow = Color.black.opacity(0.08)

    static func concernColor(_ concern: SkinConcern) -> Color {
        switch concern {
        case .blemishes: coral
        case .redness: Color(red: 0.725, green: 0.204, blue: 0.224)
        case .darkSpots: amber
        case .texture: lavender
        case .pores: moss
        case .underEye: Color(red: 0.294, green: 0.357, blue: 0.655)
        case .barrier: leaf
        }
    }
}

extension View {
    func appBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }

    func softCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(Theme.panel)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .shadow(color: Theme.softShadow, radius: 12, x: 0, y: 6)
    }
}
