import Foundation
import SwiftUI

struct Tag: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var colorHex: String
    
    init(id: UUID = UUID(), name: String, colorHex: String) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
    
    var color: Color {
        Color.fromHex(colorHex) ?? .blue
    }
}

extension Color {
    static func fromHex(_ hex: String) -> Color? {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        guard hexSanitized.count == 6 else { return nil }
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        
        return Color(red: r, green: g, blue: b)
    }
}

// MARK: - Article Tag Join

struct ArticleTag: Codable {
    let articleId: UUID
    let tagId: UUID
}
