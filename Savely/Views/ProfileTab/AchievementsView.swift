import SwiftUI

struct AchievementsView: View {
    private let badges: [Badge] = [
        Badge(title: "First steps",    subtitle: "Saved your first $1",            unlocked: true,  progress: nil,   icon: "star.fill",   bg: Color.warmAmberSoft, color: Color.warmAmber),
        Badge(title: "Full week",      subtitle: "Logged 7 days in a row",          unlocked: true,  progress: nil,   icon: "checkmark",   bg: Color.warmGreenSoft, color: Color.warmGreen),
        Badge(title: "Half-way there", subtitle: "50% on any goal",                 unlocked: true,  progress: nil,   icon: "target",      bg: Color.warmSkySoft,   color: Color.warmSky),
        Badge(title: "Steady hand",    subtitle: "30-day streak",                   unlocked: true,  progress: nil,   icon: "medal.fill",  bg: Color.warmClaySoft,  color: Color.warmClay),
        Badge(title: "Saver",          subtitle: "Save $1,000 total",               unlocked: false, progress: 0.92,  icon: "creditcard.fill", bg: Color.warmBg, color: Color.warmInkMuted),
        Badge(title: "Goal closer",    subtitle: "Complete a full goal",            unlocked: false, progress: 0.68,  icon: "target",      bg: Color.warmBg, color: Color.warmInkMuted),
        Badge(title: "Century club",   subtitle: "100-day streak",                  unlocked: false, progress: 0.47,  icon: "medal.fill",  bg: Color.warmBg, color: Color.warmInkMuted),
        Badge(title: "Big saver",      subtitle: "Save $10,000 total",              unlocked: false, progress: 0.22,  icon: "arrow.up.circle.fill", bg: Color.warmBg, color: Color.warmInkMuted),
        Badge(title: "Tipster",        subtitle: "Accept 20 AI tips",               unlocked: false, progress: 0.15,  icon: "sparkles",    bg: Color.warmBg, color: Color.warmInkMuted),
        Badge(title: "Devoted",        subtitle: "One full year with Savely",       unlocked: false, progress: 0.31,  icon: "calendar",    bg: Color.warmBg, color: Color.warmInkMuted),
    ]

    private var earned: Int { badges.filter(\.unlocked).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Heading
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(earned) earned,\n\(badges.count - earned) to go.")
                        .font(.system(size: 32, weight: .regular, design: .serif))
                        .foregroundStyle(Color.warmInk)
                        .lineSpacing(2)
                    Text("Badges unlock as you save — no pressure.")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.warmInkMuted)
                }
                .padding(.top, 8)

                // Badge list
                VStack(spacing: 10) {
                    ForEach(badges) { badge in
                        BadgeRow(badge: badge)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 32)
        }
        .background(Color.warmBg)
        .navigationTitle("Achievements")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Badge model

struct Badge: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let unlocked: Bool
    let progress: Double?
    let icon: String
    let bg: Color
    let color: Color
}

// MARK: - Badge Row

struct BadgeRow: View {
    let badge: Badge

    var body: some View {
        HStack(spacing: 14) {
            // Icon tile
            RoundedRectangle(cornerRadius: 14)
                .fill(badge.bg)
                .frame(width: 48, height: 48)
                .overlay(RoundedRectangle(cornerRadius: 14).stroke(badge.unlocked ? Color.clear : Color.warmLine, lineWidth: 1))
                .overlay(
                    Image(systemName: badge.icon)
                        .font(.system(size: 20, weight: badge.unlocked ? .semibold : .regular))
                        .foregroundStyle(badge.color)
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(badge.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(badge.unlocked ? Color.warmInk : Color.warmInkSoft)
                Text(badge.subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.warmInkMuted)

                // Progress bar for locked badges
                if !badge.unlocked, let pct = badge.progress {
                    HStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.warmLine)
                                    .frame(height: 4)
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.warmGreen)
                                    .frame(width: geo.size.width * pct, height: 4)
                            }
                        }
                        .frame(height: 4)
                        Text("\(Int(pct * 100))%")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.warmInkMuted)
                            .monospacedDigit()
                    }
                    .padding(.top, 4)
                }
            }
            Spacer()
            if badge.unlocked {
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.warmGreen)
            }
        }
        .padding(14)
        .background(Color.warmSurface)
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))
        .opacity(badge.unlocked ? 1 : 0.88)
    }
}

#Preview { AchievementsView() }
