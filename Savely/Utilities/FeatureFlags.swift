//
//  FeatureFlags.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 15/08/26.
//

import Foundation

/// Compile-time feature flags for the official App Store release.
///
/// These are deliberately simple `static let` constants — no remote config,
/// no runtime toggles (Savely is local-first; there is no backend to serve
/// flags from). Flip a value and rebuild.
enum FeatureFlags {
    /// AI tips (OpenAI-generated) are HIDDEN for the first official App
    /// Store version (decision: 2026-08-15). The data layer stays intact —
    /// `TipModel` remains in the SwiftData container so any tips already
    /// stored survive and the feature can return by flipping this flag.
    /// Gates: Dashboard's Tip of the Day card, Profile's Tip history row,
    /// Weekly Insights' tip row, and the onboarding "Receive Tips" step.
    static let tipsEnabled = false

    /// The "Auto-move $X to <goal> from this paycheck?" suggestion in the
    /// Log-income sheet. Built for real on 2026-08-15 (it started life as a
    /// hardcoded placeholder): the suggestion is computed live from goals
    /// with payday auto-move enabled (`AutoMoveSuggestion.compute` — one
    /// goal, favorite first, amount capped by the pace, the remaining
    /// target, and the income being logged), YES only arms it, and the
    /// deposit applies together with the income save. ON for the App Store
    /// release; this flag remains as the kill switch.
    static let autoMoveSuggestionsEnabled = true

    /// The Dark Mode switch in Profile. ON since the adaptive palette
    /// (Color+Warm.swift carries a dark value per token). The switch is an
    /// absolute override — off forces light, on forces dark; the system
    /// appearance is not followed (owner's decision, 2026-08-16).
    static let darkModeEnabled = true

    /// Receipt capture surface. OFF = Savely's own Warm Meadow camera
    /// (guide frame, torch, gallery import). ON = Apple's
    /// VNDocumentCameraViewController (edge detection, auto-capture,
    /// perspective correction, system chrome). Both feed the same OCR →
    /// ReceiptParser → review screen. Kept as a flag so the two can be
    /// compared on a real device — the Simulator has no camera for either
    /// (decision recorded in docs/spikes/receipt-scan-spike.md, D5).
    static let useSystemDocumentCamera = false
}
