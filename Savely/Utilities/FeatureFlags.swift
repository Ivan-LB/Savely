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
}
