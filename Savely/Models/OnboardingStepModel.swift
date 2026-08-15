//
//  OnboardingStep.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 13/11/24.
//

import SwiftUI

struct OnboardingStepModel {
    let image: String
    let title: String
    let description: String
    /// Warm Meadow tile pairing: strong color for the glyph…
    let tileColor: Color
    /// …soft companion for the tile background (e.g. warmAmber / warmAmberSoft).
    let tileBackground: Color
}
