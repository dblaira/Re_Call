import SwiftUI

/// Notorious Recall palette + type. Page surfaces are black; entry forms are white.
enum Brand {
    static let crimson = Color(red: 0xDC / 255, green: 0x14 / 255, blue: 0x3C / 255)
    static let page    = Color.black                       // list / page background
    static let card    = Color(red: 0xE6 / 255, green: 0xD4 / 255, blue: 0xAA / 255) // entry-form background (tan)
    static let ink     = Color.black
    static let dim     = Color(white: 0.6)

    /// Bodoni for editorial titles, with a graceful serif fallback if the face is absent.
    static func serif(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        Font.custom("Bodoni 72", size: size).weight(weight)
    }
}
