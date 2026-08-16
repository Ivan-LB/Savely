import SwiftUI
import UIKit

// MARK: - Warm Meadow design system palette
//
// Every color in the app comes from here. Each token carries a light and a
// dark value; SwiftUI resolves them per trait collection, so call sites
// never branch on `colorScheme`. Dark is the same notebook under a lamp —
// same hues, low chroma, one green — not a neutral-gray inversion. The
// light values are the ones documented in DESIGN.md; the dark values and
// their AA contrast checks live in docs/plans/pr-d2-adaptive-palette.md.
extension Color {
    // Ground & ink
    static let warmBg          = Color(light: 0xF6F4EE, dark: 0x161512)
    static let warmSurface     = Color(light: 0xFFFFFF, dark: 0x262420)
    static let warmInk         = Color(light: 0x1A1A17, dark: 0xF2EFE7)
    static let warmInkSoft     = Color(light: 0x55524C, dark: 0xC6C1B5)
    static let warmInkMuted    = Color(light: 0x746F66, dark: 0x9D978A) // light was #8c8880 (3.2:1); #746f66 clears AA text at 4.5:1
    static let warmLine        = Color(light: 0x1E190F, dark: 0xF2EFE7, lightAlpha: 0.08, darkAlpha: 0.10)
    static let warmLineSoft    = Color(light: 0x1E190F, dark: 0xF2EFE7, lightAlpha: 0.04, darkAlpha: 0.05)

    // The one green. `warmGreen` is green *as ink* (text, glyphs, rings,
    // bars, toggles) and brightens in dark; `warmGreenFill` is green *as a
    // surface* (CTAs, the income card, the selected radio) that carries
    // white content, and stays deep in both schemes.
    static let warmGreen       = Color(light: 0x2F6B4A, dark: 0x78B58F)
    static let warmGreenFill   = Color(light: 0x2F6B4A, dark: 0x367C56) // also "green that stays deep" as ink on white pills
    static let warmGreenDeep   = Color(light: 0x1F4A33, dark: 0xB6DCC4)
    static let warmGreenSoft   = Color(light: 0xE8F0EA, dark: 0x22382C)
    static let warmGreenTint   = Color(light: 0xF2F7F3, dark: 0x1B2A21)

    // Category tints — a glyph on a soft tile, never a fill.
    static let warmAmber       = Color(light: 0xA8741C, dark: 0xDEA64A) // light was #c48a2a (2.6:1 on amber-soft); #a8741c clears 3:1 for glyphs
    static let warmAmberSoft   = Color(light: 0xF6ECD6, dark: 0x3A2F19)
    /// Amber as *text* on an amber-soft banner (the accent itself is too light to read at 12pt).
    static let warmAmberDeep   = Color(light: 0x7A5618, dark: 0xEBC27A)
    static let warmClay        = Color(light: 0xB85C42, dark: 0xD9846A)
    static let warmClaySoft    = Color(light: 0xF6E1D8, dark: 0x3D2721)
    static let warmSky         = Color(light: 0x4A7BA6, dark: 0x7EA9D0)
    static let warmSkySoft     = Color(light: 0xDCE8F2, dark: 0x1E2D3B)
    static let warmLilac       = Color(light: 0x7D6AB8, dark: 0xB3A4DC)
    static let warmLilacSoft   = Color(light: 0xECE8F4, dark: 0x2E2740)

    // Roles that used to be hardcoded at call sites.
    /// Content drawn on `warmGreenFill` (button labels, the income card copy).
    static let warmOnGreen     = Color(light: 0xFFFFFF, dark: 0xFFFFFF)
    /// Content drawn on a `warmInk` fill (the "+" shell, the scan banner).
    /// Ink flips to light in dark mode, so its content flips to the ground.
    static let warmOnInk       = Color(light: 0xFFFFFF, dark: 0x161512)
    /// The goal ring's track and the empty part of progress bars.
    static let warmTrack       = Color(light: 0xEDE6D4, dark: 0x3A362E)
    /// The hero-card lift and the "+" shell shadow — the only shadows by rule.
    static let warmShadow      = Color(light: 0x000000, dark: 0x000000, lightAlpha: 0.06, darkAlpha: 0.45)
    /// The raised "+" shell's shadow (deeper than the hero lift).
    static let warmShellShadow = Color(light: 0x000000, dark: 0x000000, lightAlpha: 0.18, darkAlpha: 0.60)
}

extension Color {
    /// A trait-aware color from two hex values (0xRRGGBB) and per-scheme
    /// alphas. Resolved by UIKit at draw time, so it follows the window's
    /// `preferredColorScheme` and system appearance without any view code.
    /// Internal so `GoalColor` (Models/GoalModel.swift) can define its
    /// per-goal accents the same way; views should use the named tokens.
    init(light: UInt32, dark: UInt32, lightAlpha: CGFloat = 1, darkAlpha: CGFloat = 1) {
        self.init(uiColor: UIColor { traits in
            let isDark = traits.userInterfaceStyle == .dark
            return UIColor(hex: isDark ? dark : light, alpha: isDark ? darkAlpha : lightAlpha)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
