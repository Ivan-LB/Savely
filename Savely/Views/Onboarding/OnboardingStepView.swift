//
//  OnboardingStep.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 13/11/24.
//

import SwiftUI

/// One feature page of onboarding, Warm Meadow style: soft color tile with
/// the glyph, serif title, muted body. A short entrance (tile settles,
/// text rises) runs once per page; Reduce Motion shows everything at once.
struct OnboardingStepView: View {
    let step: OnboardingStepModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            RoundedRectangle(cornerRadius: 28)
                .fill(step.tileBackground)
                .frame(width: 96, height: 96)
                .overlay(
                    Image(systemName: step.image)
                        .warmFont(40, weight: .medium)
                        .foregroundStyle(step.tileColor)
                )
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)
                .accessibilityHidden(true)

            VStack(spacing: 12) {
                Text(step.title)
                    .warmFont(30, weight: .regular, design: .serif)
                    .foregroundStyle(Color.warmInk)
                    .multilineTextAlignment(.center)

                Text(step.description)
                    .warmFont(15)
                    .foregroundStyle(Color.warmInkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 300)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 10)
        }
        .padding(.horizontal, 24)
        .onAppear {
            guard !appeared else { return }
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.9).delay(0.05)) {
                    appeared = true
                }
            }
        }
    }
}

#Preview {
    OnboardingStepView(step: OnboardingData.steps[0])
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmBg)
}
