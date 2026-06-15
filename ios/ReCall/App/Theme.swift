import SwiftUI

/// Notorious Recall palette + type. Page surfaces are black; entry forms are white.
enum Brand {
    static let crimson = Color(red: 0xDC / 255, green: 0x14 / 255, blue: 0x3C / 255)
    static let page    = Color.black                       // list / page background
    static let card    = Color(red: 0xE6 / 255, green: 0xD4 / 255, blue: 0xAA / 255) // entry-form background (tan)
    static let ink     = Color.black
    static let dim     = Color(white: 0.6)

    // Reminders-screen palette (from the Figma "Screen / Reminders" frame).
    static let tan         = Color(hex: 0xD5C194)   // RECALL band + tab bar
    static let nearBlack   = Color(hex: 0x0A0A0A)   // hero background
    static let darkRed     = Color(hex: 0xB00124)   // story / tile red
    static let recallBlue  = Color(hex: 0x021784)   // "RECALL" label
    static let cyan        = Color(hex: 0x18C8CF)   // "Capture first" card
    static let tileBlue    = Color(hex: 0x0F288E)   // blue tile / cyan card text
    static let tileGray    = Color(hex: 0xCFD3D9)   // light gray tile
    static let tileDark    = Color(hex: 0x1A1A1A)   // near-black tile
    static let tabActive   = Color(hex: 0x2E2716)   // active tab label
    static let tabInactive = Color(hex: 0x7D6A45)   // inactive tab label

    /// Bodoni for editorial titles, with a graceful serif fallback if the face is absent.
    static func serif(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.custom("Bodoni 72", size: size).weight(weight)
    }
}

extension Color {
    /// 0xRRGGBB convenience initializer for design-token colors.
    init(hex: UInt, alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}
