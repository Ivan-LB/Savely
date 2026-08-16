//
//  SproutMark.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 15/08/26.
//

import SwiftUI

/// The Savely brand mark (2026-08 rebrand): a two-leaf sprout growing from
/// an amber seed. These shapes share the app icon's 120-unit design space,
/// so the in-app mark and the icon are geometrically identical.
///
/// `SplashScreenView` animates the individual shapes (stem trim, leaf
/// unfurl); `SproutMark` below is the static, fully-grown composition for
/// everywhere else (onboarding, empty states, about screens).

func sproutPoint(_ x: CGFloat, _ y: CGFloat, in rect: CGRect) -> CGPoint {
    CGPoint(x: rect.minX + x / 120 * rect.width, y: rect.minY + y / 120 * rect.height)
}

struct SproutStemShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: sproutPoint(60, 87, in: rect))
        p.addCurve(
            to: sproutPoint(60, 56, in: rect),
            control1: sproutPoint(52, 76, in: rect),
            control2: sproutPoint(68, 68, in: rect)
        )
        return p
    }
}

struct SeedShape: Shape {
    func path(in rect: CGRect) -> Path {
        let center = sproutPoint(60, 92, in: rect)
        let radius = 9 / 120 * rect.width
        return Path(ellipseIn: CGRect(
            x: center.x - radius, y: center.y - radius,
            width: radius * 2, height: radius * 2
        ))
    }
}

struct SproutLeafShape: Shape {
    enum Side { case left, right }
    let side: Side

    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: sproutPoint(60, 56, in: rect))
        switch side {
        case .left:
            p.addCurve(
                to: sproutPoint(36, 26, in: rect),
                control1: sproutPoint(42, 54, in: rect),
                control2: sproutPoint(34, 40, in: rect)
            )
            p.addCurve(
                to: sproutPoint(60, 56, in: rect),
                control1: sproutPoint(52, 28, in: rect),
                control2: sproutPoint(60, 42, in: rect)
            )
        case .right:
            p.addCurve(
                to: sproutPoint(82, 28, in: rect),
                control1: sproutPoint(74, 52, in: rect),
                control2: sproutPoint(82, 40, in: rect)
            )
            p.addCurve(
                to: sproutPoint(60, 56, in: rect),
                control1: sproutPoint(68, 30, in: rect),
                control2: sproutPoint(60, 42, in: rect)
            )
        }
        p.closeSubpath()
        return p
    }
}

/// Static fully-grown sprout. Defaults to the light-mode brand colors
/// (deep greens on whatever background the caller provides).
struct SproutMark: View {
    var leafPrimary: Color = .warmGreen
    var leafSecondary: Color = Color(red: 0.216, green: 0.475, blue: 0.353) // #37795a — brand mark, deliberately fixed
    var seed: Color = .warmAmber
    /// Stem line width as a fraction of the mark's width (icon uses 5.5/120).
    var stemWidthRatio: CGFloat = 5.5 / 120

    var body: some View {
        GeometryReader { geo in
            ZStack {
                SproutStemShape()
                    .stroke(leafPrimary, style: StrokeStyle(
                        lineWidth: geo.size.width * stemWidthRatio, lineCap: .round
                    ))
                SeedShape()
                    .fill(seed)
                SproutLeafShape(side: .left)
                    .fill(leafPrimary)
                SproutLeafShape(side: .right)
                    .fill(leafSecondary)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }
}

#Preview {
    SproutMark()
        .frame(width: 120, height: 120)
        .padding()
        .background(Color.warmBg)
}
