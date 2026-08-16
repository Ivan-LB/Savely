import SwiftUI

/// Animated splash (2026-08): the sprout mark grows from its seed — amber
/// seed lands, stem draws upward, leaves unfurl — then the wordmark reveals
/// letter by letter. Uses the icon's dark-variant palette. The whole
/// sequence is skipped for Reduce Motion users (single crossfade instead).
struct SplashScreenView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isSplashEnded = false

    // Sprout
    @State private var seedVisible = false
    @State private var stemProgress: CGFloat = 0
    @State private var leftLeafVisible = false
    @State private var rightLeafVisible = false

    // Wordmark
    @State private var wordVisible = false

    // Hairline rule
    @State private var rulerScaleX: CGFloat = 0

    // Tagline
    @State private var taglineOpacity: Double = 0

    private let letters = Array("Savely")

    // Dark-variant palette (matches AppIcon's dark appearance)
    // Deliberate constants: the splash is the same dark-green frame in both
    // appearances (it is the brand moment, not a screen), so it does not use
    // the adaptive tokens.
    private let bgInk = Color(red: 0.122, green: 0.169, blue: 0.137)      // #1f2b23
    private let leafLight = Color(red: 0.490, green: 0.722, blue: 0.596)  // #7db898
    private let leafShaded = Color(red: 0.365, green: 0.612, blue: 0.486) // #5d9c7c
    private let cream = Color(red: 0.965, green: 0.957, blue: 0.933)      // #f6f4ee

    var body: some View {
        ZStack {
            if isSplashEnded {
                ContentView()
                    .transition(.opacity)
            } else {
                splashContent
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }

    private var splashContent: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                bgInk.ignoresSafeArea()

                // Radial vignette for depth
                RadialGradient(
                    colors: [Color.clear, Color.black.opacity(0.25)],
                    center: .center,
                    startRadius: geo.size.width * 0.4,
                    endRadius: geo.size.width * 1.1
                )
                .ignoresSafeArea()

                VStack(spacing: 34) {
                    sprout
                        .frame(width: 150, height: 150)

                    VStack(spacing: 12) {
                        // Wordmark — letter by letter
                        HStack(spacing: 0) {
                            ForEach(0..<letters.count, id: \.self) { i in
                                Text(String(letters[i]))
                                    .font(.system(size: 52, weight: .regular, design: .serif))
                                    .foregroundStyle(cream)
                                    .opacity(wordVisible ? 1 : 0)
                                    .offset(y: wordVisible ? 0 : 18)
                                    .blur(radius: wordVisible ? 0 : 3)
                                    .animation(
                                        reduceMotion
                                            ? .easeOut(duration: 0.01)
                                            : .easeOut(duration: 0.45).delay(Double(i) * 0.07),
                                        value: wordVisible
                                    )
                            }
                        }

                        // Hairline rule
                        Rectangle()
                            .fill(cream.opacity(0.4))
                            .frame(width: 120, height: 1)
                            .scaleEffect(x: rulerScaleX, anchor: .center)

                        // Tagline
                        Text("Save with intention")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(cream.opacity(0.82))
                            .tracking(4)
                            .textCase(.uppercase)
                            .opacity(taglineOpacity)
                            .offset(y: taglineOpacity == 0 ? 4 : 0)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .onAppear(perform: runAnimation)
        }
    }

    /// The sprout mark, drawn natively so each part can animate:
    /// stem below seed (matches the icon's layer order), leaves anchored
    /// at the stem tip (60,56 in the 120-unit design space).
    private var sprout: some View {
        ZStack {
            SproutStemShape()
                .trim(from: 0, to: stemProgress)
                .stroke(leafLight, style: StrokeStyle(lineWidth: 6.9, lineCap: .round))

            SeedShape()
                .fill(Color.warmAmber)
                .opacity(seedVisible ? 1 : 0)
                .offset(y: seedVisible ? 0 : -34)

            SproutLeafShape(side: .left)
                .fill(leafLight)
                .scaleEffect(leftLeafVisible ? 1 : 0.01, anchor: leafAnchor)
                .rotationEffect(.degrees(leftLeafVisible ? 0 : -12), anchor: leafAnchor)
                .opacity(leftLeafVisible ? 1 : 0)

            SproutLeafShape(side: .right)
                .fill(leafShaded)
                .scaleEffect(rightLeafVisible ? 1 : 0.01, anchor: leafAnchor)
                .rotationEffect(.degrees(rightLeafVisible ? 0 : 12), anchor: leafAnchor)
                .opacity(rightLeafVisible ? 1 : 0)
        }
    }

    /// Stem tip (60,56) in the 120-unit space, as a UnitPoint.
    private var leafAnchor: UnitPoint { UnitPoint(x: 0.5, y: 56.0 / 120.0) }

    private func runAnimation() {
        guard !reduceMotion else {
            // Reduce Motion: everything appears in one gentle crossfade.
            withAnimation(.easeOut(duration: 0.35)) {
                seedVisible = true
                stemProgress = 1
                leftLeafVisible = true
                rightLeafVisible = true
                wordVisible = true
                rulerScaleX = 1
                taglineOpacity = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                withAnimation(.easeInOut(duration: 0.3)) { isSplashEnded = true }
            }
            return
        }

        // 1. Seed lands — confident deceleration, one soft settle, no bounce.
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            seedVisible = true
        }

        // 2. Stem draws upward out of the seed.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
            withAnimation(.easeOut(duration: 0.55)) {
                stemProgress = 1
            }
        }

        // 3. Leaves unfurl from the stem tip, staggered.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.90) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                leftLeafVisible = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.05) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                rightLeafVisible = true
            }
        }

        // 4. Wordmark reveals only after the sprout has finished growing.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            wordVisible = true
        }

        // 5. Hairline draws from center.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.10) {
            withAnimation(.easeOut(duration: 0.50)) {
                rulerScaleX = 1
            }
        }

        // 6. Tagline fades in.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.40) {
            withAnimation(.easeOut(duration: 0.40)) {
                taglineOpacity = 1
            }
        }

        // 7. Transition to the app — exit faster than any entrance.
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.40) {
            withAnimation(.easeInOut(duration: 0.40)) {
                isSplashEnded = true
            }
        }
    }
}

// Sprout geometry lives in Views/Components/SproutMark.swift (shared with
// the static in-app mark) — this file animates those shapes directly.

#Preview {
    SplashScreenView()
}
