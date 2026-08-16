//
//  Font+Warm.swift
//  Savely
//
//  Dynamic Type for a design specified in fixed point sizes. `.warmFont(14)`
//  renders at exactly 14pt at the default content size — so nothing in the
//  app changes for a user who never touched the setting — and follows the
//  user's reading size from there, the way `.body` / `.title` do.
//
//  Why a modifier and not `Font.warm(...)`: the modifier reads the
//  size category from the environment, so the view re-renders when the
//  user changes it. A `Font` value computed once would bake the old size.
//

import SwiftUI
import UIKit

extension View {
    /// System font at `size` points (default content size), scaled with
    /// Dynamic Type relative to `style`. When `style` is nil it is chosen
    /// from the size so headings scale like headings and captions like
    /// captions (large styles grow less at accessibility sizes than body).
    func warmFont(
        _ size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        relativeTo style: Font.TextStyle? = nil
    ) -> some View {
        modifier(WarmFontModifier(size: size, weight: weight, design: design, style: style ?? WarmType.style(for: size)))
    }
}

/// The scaling policy, kept separate from the modifier so it can be tested.
enum WarmType {
    /// The text style whose Dynamic Type curve a fixed size should follow.
    static func style(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 30...: return .largeTitle
        case 24..<30: return .title
        case 20..<24: return .title2
        case 17..<20: return .title3
        case 15..<17: return .body
        case 13..<15: return .subheadline
        case 12..<13: return .footnote
        default: return .caption
        }
    }

    /// The point size to render `size` at for a given content size category.
    static func scaledSize(_ size: CGFloat, relativeTo style: Font.TextStyle, sizeCategory: ContentSizeCategory) -> CGFloat {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(sizeCategory))
        return UIFontMetrics(forTextStyle: style.uiTextStyle).scaledValue(for: size, compatibleWith: traits)
    }
}

private struct WarmFontModifier: ViewModifier {
    @Environment(\.sizeCategory) private var sizeCategory
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    let style: Font.TextStyle

    func body(content: Content) -> some View {
        content.font(.system(
            size: WarmType.scaledSize(size, relativeTo: style, sizeCategory: sizeCategory),
            weight: weight,
            design: design
        ))
    }
}

extension View {
    /// Enlarges the hit area of a small control to the 44×44 pt minimum
    /// without changing how it looks. Layout may grow by a few points when
    /// the visual is smaller than 44 — that is the point.
    func tappable44() -> some View {
        frame(minWidth: 44, minHeight: 44).contentShape(Rectangle())
    }
}

extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .body: return .body
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        @unknown default: return .body
        }
    }
}

extension UIContentSizeCategory {
    init(_ category: ContentSizeCategory) {
        switch category {
        case .extraSmall: self = .extraSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .extraLarge: self = .extraLarge
        case .extraExtraLarge: self = .extraExtraLarge
        case .extraExtraExtraLarge: self = .extraExtraExtraLarge
        case .accessibilityMedium: self = .accessibilityMedium
        case .accessibilityLarge: self = .accessibilityLarge
        case .accessibilityExtraLarge: self = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge: self = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge: self = .accessibilityExtraExtraExtraLarge
        @unknown default: self = .large
        }
    }
}
