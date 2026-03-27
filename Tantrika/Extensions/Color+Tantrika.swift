import SwiftUI

// MARK: — Hex initializer

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        switch hex.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8)  & 0xFF) / 255
            b = Double( int        & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: — Design tokens

extension Color {
    /// Parchment — dominant background on every screen
    static let tantrikaBackground  = Color(hex: "#F5F0EA")
    /// Warm Cream — cards, sheets, lesson rows
    static let tantrikaSurface     = Color(hex: "#EDE5D8")
    /// Terracotta — primary CTA only; use sparingly
    static let tantrikaAccent      = Color(hex: "#C4624A")
    /// Deep Brown — primary text
    static let tantrikaText        = Color(hex: "#2C1A12")
    /// Muted Brown — captions, metadata, ghost button labels
    static let tantrikaTextMuted   = Color(hex: "#7A6355")
    /// Sage — free preview badge ONLY; never for text or primary actions
    static let tantrikaSage        = Color(hex: "#8A9E85")
}
