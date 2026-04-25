import SwiftUI

struct SplashScreenView: View {
    @State private var isSplashEnded = false

    // Logo
    @State private var logoY: CGFloat = -80
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0

    // Wordmark
    @State private var wordVisible = false

    // Hairline rule
    @State private var rulerScaleX: CGFloat = 0

    // Tagline
    @State private var taglineOpacity: Double = 0

    private let letters = Array("Savely")

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
        ZStack {
            // Background
            Color.warmGreen.ignoresSafeArea()

            // Radial vignette for depth
            RadialGradient(
                colors: [Color.clear, Color.black.opacity(0.20)],
                center: .center,
                startRadius: UIScreen.main.bounds.width * 0.4,
                endRadius: UIScreen.main.bounds.width * 1.1
            )
            .ignoresSafeArea()

            VStack(spacing: 30) {
                // Logo
                Image("AppUtilityIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 132, height: 132)
                    .shadow(color: .black.opacity(0.22), radius: 20, x: 0, y: 10)
                    .offset(y: logoY)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                VStack(spacing: 12) {
                    // Wordmark — letter by letter
                    HStack(spacing: 0) {
                        ForEach(0..<letters.count, id: \.self) { i in
                            Text(String(letters[i]))
                                .font(.system(size: 52, weight: .regular, design: .serif))
                                .foregroundStyle(.white)
                                .opacity(wordVisible ? 1 : 0)
                                .offset(y: wordVisible ? 0 : 18)
                                .blur(radius: wordVisible ? 0 : 3)
                                .animation(
                                    .easeOut(duration: 0.45).delay(Double(i) * 0.07),
                                    value: wordVisible
                                )
                        }
                    }

                    // Hairline rule
                    Rectangle()
                        .fill(Color.white.opacity(0.45))
                        .frame(width: 120, height: 1)
                        .scaleEffect(x: rulerScaleX, anchor: .center)

                    // Tagline
                    Text("Save with intention")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color.white.opacity(0.82))
                        .tracking(4)
                        .textCase(.uppercase)
                        .opacity(taglineOpacity)
                        .offset(y: taglineOpacity == 0 ? 4 : 0)
                }
            }
        }
        .onAppear(perform: runAnimation)
    }

    private func runAnimation() {
        // 1. Logo drops with spring
        withAnimation(.spring(response: 0.52, dampingFraction: 0.60)) {
            logoY = 0
            logoScale = 1.0
            logoOpacity = 1.0
        }

        // 2. Wordmark letters reveal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) {
            wordVisible = true
        }

        // 3. Hairline draws from center
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
            withAnimation(.easeOut(duration: 0.50)) {
                rulerScaleX = 1
            }
        }

        // 4. Tagline fades in
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.55) {
            withAnimation(.easeOut(duration: 0.40)) {
                taglineOpacity = 1
            }
        }

        // 5. Transition to app
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.80) {
            withAnimation(.easeInOut(duration: 0.40)) {
                isSplashEnded = true
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
