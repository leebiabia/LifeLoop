import SwiftUI

extension Color {
    static let lifeBlue   = Color(hex: "#007AFF")
    static let lifeGreen  = Color(hex: "#34C759")
    static let lifeOrange = Color(hex: "#FF9500")
    static let lifeRed    = Color(hex: "#FF3B30")
    static let lifePurple = Color(hex: "#AF52DE")
    static let lifeIndigo = Color(hex: "#5856D6")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
