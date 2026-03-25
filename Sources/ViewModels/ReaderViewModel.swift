import Foundation
import Combine

final class ReaderViewModel: ObservableObject {
    @Published var readerWidth: ReaderWidth = .medium
    @Published var readerFont: ReaderFont = .system
    @Published var readerFontSize: Int = 16
    @Published var readerTheme: ReaderTheme = .light

    private let widthKey = "readerWidth"
    private let fontKey = "readerFont"
    private let fontSizeKey = "readerFontSize"
    private let themeKey = "readerTheme"

    init() {
        if let w = UserDefaults.standard.string(forKey: widthKey),
           let width = ReaderWidth(rawValue: w) { readerWidth = width }
        if let f = UserDefaults.standard.string(forKey: fontKey),
           let font = ReaderFont(rawValue: f) { readerFont = font }
        readerFontSize = UserDefaults.standard.integer(forKey: fontSizeKey)
        if readerFontSize < 12 || readerFontSize > 24 { readerFontSize = 16 }
        if let t = UserDefaults.standard.string(forKey: themeKey),
           let theme = ReaderTheme(rawValue: t) { readerTheme = theme }
    }

    func save() {
        UserDefaults.standard.set(readerWidth.rawValue, forKey: widthKey)
        UserDefaults.standard.set(readerFont.rawValue, forKey: fontKey)
        UserDefaults.standard.set(readerFontSize, forKey: fontSizeKey)
        UserDefaults.standard.set(readerTheme.rawValue, forKey: themeKey)
    }

    enum ReaderWidth: String, CaseIterable {
        case narrow = "Narrow"
        case medium = "Medium"
        case wide = "Wide"

        var maxWidth: CGFloat {
            switch self {
            case .narrow: return 500
            case .medium: return 700
            case .wide: return 900
            }
        }
    }

    enum ReaderFont: String, CaseIterable {
        case system = "System"
        case serif = "Serif"
        case mono = "Mono"

        var cssName: String {
            switch self {
            case .system: return "-apple-system, BlinkMacSystemFont, sans-serif"
            case .serif: return "Georgia, Times New Roman, serif"
            case .mono: return "Menlo, Courier New, monospace"
            }
        }
    }

    enum ReaderTheme: String, CaseIterable {
        case light = "Light"
        case dark = "Dark"
        case sepia = "Sepia"

        var backgroundColor: String {
            switch self {
            case .light: return "#FFFFFF"
            case .dark: return "#1C1C1E"
            case .sepia: return "#F4ECD8"
            }
        }

        var textColor: String {
            switch self {
            case .light: return "#333333"
            case .dark: return "#E5E5E7"
            case .sepia: return "#5B4636"
            }
        }
    }
}
