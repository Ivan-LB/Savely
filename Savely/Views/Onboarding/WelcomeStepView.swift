//
//  WelcomeStepView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 15/08/26.
//

import SwiftUI

/// First onboarding page: the sprout mark plus the local-first promise —
/// the one thing worth saying before anything else now that Savely has no
/// accounts (2026-08). Same entrance rhythm as the feature steps.
struct WelcomeStepView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 28) {
            SproutMark()
                .frame(width: 110, height: 110)
                .scaleEffect(appeared ? 1 : 0.92)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: 12) {
                Text(Strings.Onboarding.welcomeTitle)
                    .warmFont(30, weight: .regular, design: .serif)
                    .foregroundStyle(Color.warmInk)
                    .multilineTextAlignment(.center)

                Text(Strings.Onboarding.welcomeLabel)
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
    WelcomeStepView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.warmBg)
}
