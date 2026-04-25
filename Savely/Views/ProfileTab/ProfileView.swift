import SwiftUI
import SwiftData

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var appViewModel: AppViewModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \IncomeModel.date, order: .reverse) private var incomes: [IncomeModel]
    @State private var showingEditProfile = false
    @State private var showingAchievements = false
    @State private var showingTipHistory = false

    private var lifetimeIncome: Double { incomes.reduce(0) { $0 + $1.amount } }
    private var displayInitial: String {
        viewModel.displayName.first.map { String($0).uppercased() } ?? "U"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // — Notification bell top right —
                    HStack {
                        Spacer()
                        Button(action: {}) {
                            Image(systemName: "bell")
                                .font(.system(size: 18))
                                .foregroundStyle(Color.warmInk)
                                .frame(width: 40, height: 40)
                                .background(Color.warmSurface)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.warmLine, lineWidth: 1))
                        }
                    }
                    .padding(.top, 8)

                    // — Identity card —
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.warmAmberSoft)
                            .frame(width: 64, height: 64)
                            .overlay(
                                Text(displayInitial)
                                    .font(.system(size: 30, weight: .regular, design: .serif))
                                    .foregroundStyle(Color.warmAmber)
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text(viewModel.displayName.isEmpty ? "User" : viewModel.displayName)
                                .font(.system(size: 22, weight: .regular, design: .serif))
                                .foregroundStyle(Color.warmInk)
                            Text(viewModel.email.isEmpty ? "—" : viewModel.email)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.warmInkMuted)
                        }
                        Spacer()
                        Button(action: { showingEditProfile = true }) {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.warmInkMuted)
                                .frame(width: 32, height: 32)
                                .background(Color.warmBg)
                                .cornerRadius(10)
                        }
                    }
                    .padding(20)
                    .background(Color.warmSurface)
                    .cornerRadius(22)
                    .overlay(RoundedRectangle(cornerRadius: 22).stroke(Color.warmLine, lineWidth: 1))

                    // — Lifetime savings card —
                    ZStack(alignment: .topTrailing) {
                        Circle()
                            .fill(Color.white.opacity(0.08))
                            .frame(width: 140, height: 140)
                            .offset(x: 30, y: -20)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("LIFETIME INCOME")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Color.white.opacity(0.7))
                                .tracking(0.8)
                            Text(formattedAmount(lifetimeIncome))
                                .font(.system(size: 40, weight: .regular, design: .serif))
                                .foregroundStyle(.white)
                            Text("Total income logged in Savely")
                                .font(.system(size: 13))
                                .foregroundStyle(Color.white.opacity(0.75))
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                    }
                    .background(Color.warmGreen)
                    .cornerRadius(22)
                    .clipped()

                    // — Achievements preview —
                    VStack(spacing: 12) {
                        HStack {
                            Text("Achievements")
                                .font(.system(size: 18, weight: .regular, design: .serif))
                                .foregroundStyle(Color.warmInk)
                            Spacer()
                            Button(action: { showingAchievements = true }) {
                                Text("See all ›")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundStyle(Color.warmGreen)
                            }
                        }
                        HStack(spacing: 10) {
                            ForEach(badgePreviews, id: \.icon) { b in
                                BadgeTile(icon: b.icon, bg: b.bg, color: b.color, unlocked: b.unlocked)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.warmSurface)
                    .cornerRadius(20)
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.warmLine, lineWidth: 1))

                    // — Settings —
                    ProfileSection(header: "Settings") {
                        SettingsToggleRow(icon: "bell.fill", title: "Notifications", isOn: $viewModel.expenseReminders)
                        WarmDivider()
                        SettingsToggleRow(icon: "moon.fill", title: "Dark Mode", isOn: $viewModel.darkMode)
                        WarmDivider()
                        SettingsNavRow(icon: "lock.shield.fill", title: "Change Password", onTap: {})
                        WarmDivider()
                        SettingsNavRow(icon: "doc.text.fill", title: "Weekly PDF report", onTap: {})
                    }

                    ProfileSection(header: "About") {
                        SettingsNavRow(icon: "sparkles", title: "Tip history", detail: "128 tips", onTap: { showingTipHistory = true })
                        WarmDivider()
                        SettingsNavRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign out", color: Color.warmClay, onTap: {
                            Task { try? AuthenticationManager.shared.signOut() }
                        })
                    }

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .background(Color.warmBg)
            .navigationBarHidden(true)
            .alert(isPresented: $viewModel.showAlert) {
                Alert(title: Text(Strings.Errors.noticeLabel), message: Text(viewModel.alertMessage), dismissButton: .default(Text(Strings.Buttons.okButton)))
            }
            .sheet(isPresented: $showingEditProfile) { EditProfileSheet(viewModel: viewModel) }
            .navigationDestination(isPresented: $showingAchievements) { AchievementsView() }
            .navigationDestination(isPresented: $showingTipHistory) { TipHistoryView() }
            .onAppear { viewModel.setModelContext(modelContext) }
        }
    }

    // Badge previews (static mock — real achievements system can be wired later)
    private struct BadgePreview { let icon: String; let bg: Color; let color: Color; let unlocked: Bool }
    private var badgePreviews: [BadgePreview] { [
        BadgePreview(icon: "star.fill",   bg: Color.warmAmberSoft, color: Color.warmAmber, unlocked: true),
        BadgePreview(icon: "checkmark",   bg: Color.warmGreenSoft, color: Color.warmGreen, unlocked: true),
        BadgePreview(icon: "target",      bg: Color.warmSkySoft,   color: Color.warmSky,   unlocked: true),
        BadgePreview(icon: "medal.fill",  bg: Color.warmClaySoft,  color: Color.warmClay,  unlocked: true),
        BadgePreview(icon: "lock.fill",   bg: Color.warmBg,        color: Color.warmInkMuted, unlocked: false),
        BadgePreview(icon: "lock.fill",   bg: Color.warmBg,        color: Color.warmInkMuted, unlocked: false),
    ] }

    private func formattedAmount(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "$"; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }
}

// MARK: - Badge Tile

struct BadgeTile: View {
    let icon: String; let bg: Color; let color: Color; let unlocked: Bool
    var body: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(bg)
            .overlay(RoundedRectangle(cornerRadius: 14).stroke(unlocked ? Color.clear : Color.warmLine, lineWidth: 1))
            .overlay(Image(systemName: icon).font(.system(size: 18, weight: unlocked ? .semibold : .regular)).foregroundStyle(color))
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
    }
}

// MARK: - Profile Section wrapper

struct ProfileSection<Content: View>: View {
    let header: String
    @ViewBuilder let content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(header.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.warmInkMuted)
                .tracking(0.8)
                .padding(.leading, 4)
            VStack(spacing: 0) { content() }
                .background(Color.warmSurface)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))
        }
    }
}

struct WarmDivider: View {
    var body: some View {
        Rectangle().fill(Color.warmLineSoft).frame(height: 1).padding(.leading, 60)
    }
}

// MARK: - Settings rows (redesigned)

struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(Color.warmInkSoft)
                .frame(width: 28)
            Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(Color.warmInk)
            Spacer()
            Toggle("", isOn: $isOn).labelsHidden().tint(Color.warmGreen)
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}

struct SettingsNavRow: View {
    let icon: String
    let title: String
    var detail: String? = nil
    var color: Color = Color.warmInkSoft
    let onTap: () -> Void
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
                    .frame(width: 28)
                Text(title).font(.system(size: 14, weight: .medium)).foregroundStyle(color == Color.warmInkSoft ? Color.warmInk : color)
                Spacer()
                if let d = detail {
                    Text(d).font(.system(size: 13)).foregroundStyle(Color.warmInkMuted)
                }
                if color != Color.warmClay {
                    Image(systemName: "chevron.right").font(.system(size: 12)).foregroundStyle(Color.warmInkMuted)
                }
            }
            .padding(.horizontal, 16).padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Edit Profile Sheet (unchanged)

struct EditProfileSheet: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Display Name", text: $viewModel.displayName)
                    TextField("Email", text: $viewModel.email)
                        .textContentType(.emailAddress).keyboardType(.emailAddress).autocapitalization(.none)
                }
            }
            .navigationTitle("Edit Profile").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { Task { await viewModel.updatePersonalInformation(); dismiss() } }.fontWeight(.semibold)
                }
            }
        }
    }
}

struct InnerHeightPreferenceKey: PreferenceKey {
    static let defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

#Preview { ProfileView() }
