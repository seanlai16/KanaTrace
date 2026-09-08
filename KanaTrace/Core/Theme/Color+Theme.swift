import SwiftUI

extension Color {
    static let paper = Color(hex: 0xF6F1E8)
    static let paperRaised = Color(hex: 0xFFFCF5)
    static let ink = Color(hex: 0x1C1917)
    static let inkMuted = Color(hex: 0x8A8178)
    static let inkFaint = Color(hex: 0xD9D0C4)
    static let indigo = Color(hex: 0x2F4F6B)
    static let indigoShadow = Color(hex: 0x243D54)
    static let vermillion = Color(hex: 0xC45C26)
    static let reject = Color(hex: 0xB42318)
    static let accept = Color(hex: 0x2F6B4F)

    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
