import SwiftUI
import SwiftData

struct GoalsView: View {
    @Binding var showAddGoalFlow: Bool
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = GoalsViewModel()

    private var totalSaved:    Double { viewModel.goals.reduce(0) { $0 + $1.current } }
    private var totalTarget:   Double { viewModel.goals.reduce(0) { $0 + $1.target } }
    private var overallProgress: Double { totalTarget > 0 ? min(totalSaved / totalTarget, 1.0) : 0 }

    var body: some View {
        Group {
            if viewModel.goals.isEmpty {
                GoalsEmptyStateView(onCreateGoal: { showAddGoalFlow = true })
            } else {
                goalsListView
            }
        }
        .background(Color.warmBg.ignoresSafeArea())
        .navigationBarHidden(true)
        .onAppear { viewModel.setModelContext(modelContext) }
        .onChange(of: showAddGoalFlow) { _, isShowing in
            if !isShowing { viewModel.fetchGoals() }
        }
        .alert(isPresented: $viewModel.showError) {
            Alert(
                title: Text(Strings.Errors.errorLabel),
                message: Text(viewModel.errorMessage),
                dismissButton: .default(Text(Strings.Buttons.okButton))
            )
        }
    }

    // MARK: Goals list

    private var goalsListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Goals")
                            .font(.system(size: 34, weight: .regular, design: .serif))
                            .foregroundStyle(Color.warmInk)
                        Text("\(viewModel.goals.count) active · \(formattedAmount(totalSaved)) saved of \(formattedAmount(totalTarget))")
                            .font(.system(size: 14)).foregroundStyle(Color.warmInkMuted)
                    }
                    Spacer()
                    Button(action: { showAddGoalFlow = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                            .frame(width: 40, height: 40).background(Color.warmInk).cornerRadius(14)
                    }
                }
                .padding(.top, 8)

                // Overall stacked progress bar
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Progress overall")
                            .font(.system(size: 12, weight: .semibold)).foregroundStyle(Color.warmInkMuted)
                            .tracking(0.6).textCase(.uppercase)
                        Spacer()
                        Text("\(Int(overallProgress * 100))%")
                            .font(.system(size: 22, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                    }
                    GeometryReader { geo in
                        HStack(spacing: 0) {
                            ForEach(viewModel.goals) { goal in
                                let w = totalTarget > 0 ? (goal.current / totalTarget) * geo.size.width : 0
                                Rectangle().fill(goal.color).frame(width: max(0, w))
                            }
                        }
                        .frame(height: 10).background(Color.warmLine).cornerRadius(5)
                    }
                    .frame(height: 10)
                }
                .padding(18)
                .background(Color.warmSurface).cornerRadius(18)
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.warmLine, lineWidth: 1))

                VStack(spacing: 12) {
                    ForEach(viewModel.goals) { goal in
                        NavigationLink(destination: GoalDetailView(goal: goal)) {
                            WarmGoalCard(
                                goal: goal,
                                onFavoriteToggle: { viewModel.setFavorite(goal: goal) },
                                onDelete: { viewModel.deleteGoal(goal) }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                Spacer(minLength: 16)
            }
            .padding(.horizontal, 20).padding(.bottom, 24)
        }
    }

    private func formattedAmount(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "$"; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }
}

// MARK: - Empty state

struct GoalsEmptyStateView: View {
    let onCreateGoal: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Goals")
                            .font(.system(size: 34, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                        Text("Nothing here yet — let's plant the first one.")
                            .font(.system(size: 14)).foregroundStyle(Color.warmInkMuted)
                    }
                    Spacer()
                    Button(action: onCreateGoal) {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                            .frame(width: 40, height: 40).background(Color.warmInk).cornerRadius(14)
                    }
                }
                .padding(.top, 8).padding(.horizontal, 20).padding(.bottom, 28)

                // Dashed invitation card
                VStack(spacing: 20) {
                    // Empty ring with Day One badge
                    ZStack(alignment: .topTrailing) {
                        ZStack {
                            Circle()
                                .stroke(Color(red: 0.89, green: 0.867, blue: 0.816), lineWidth: 14)
                                .frame(width: 160, height: 160)
                            ZStack {
                                Circle().fill(Color.warmGreenSoft).frame(width: 64, height: 64)
                                Image(systemName: "target")
                                    .font(.system(size: 26)).foregroundStyle(Color.warmGreen)
                            }
                        }
                        Text("Day one")
                            .font(.system(size: 10, weight: .bold)).foregroundStyle(Color.warmAmber)
                            .tracking(0.8).textCase(.uppercase)
                            .padding(.horizontal, 10).padding(.vertical, 4)
                            .background(Color.warmAmberSoft).clipShape(Capsule())
                            .rotationEffect(.degrees(8))
                            .offset(x: 14, y: -6)
                    }
                    .padding(.top, 8)

                    VStack(spacing: 10) {
                        Text("What are you saving for?")
                            .font(.system(size: 28, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                            .multilineTextAlignment(.center)
                        Text("A goal is a name, a number, and a date.\nSavely takes care of the rest.")
                            .font(.system(size: 14)).foregroundStyle(Color.warmInkSoft)
                            .multilineTextAlignment(.center).lineSpacing(3)
                    }

                    Button(action: onCreateGoal) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus").font(.system(size: 14, weight: .semibold))
                            Text("Create your first goal").font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).frame(height: 50)
                        .background(Color.warmGreen).cornerRadius(14)
                    }

                    // Suggestion chips
                    HStack(spacing: 8) {
                        ForEach([("🌿","Emergency fund"),("✈️","A trip"),("🏡","Down payment")], id: \.0) { item in
                            Button(action: onCreateGoal) {
                                HStack(spacing: 6) {
                                    Text(item.0).font(.system(size: 13))
                                    Text(item.1).font(.system(size: 12)).foregroundStyle(Color.warmInkSoft)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color.warmBg)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(Color.warmLine, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.bottom, 8)
                }
                .padding(28)
                .frame(maxWidth: .infinity)
                .background(Color.warmSurface)
                .cornerRadius(28)
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .foregroundStyle(Color.warmLine)
                )
                .padding(.horizontal, 20).padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Warm Goal Card

struct WarmGoalCard: View {
    let goal: GoalModel
    let onFavoriteToggle: () -> Void
    let onDelete: () -> Void
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(goal.color).frame(width: 44, height: 44)
                    .overlay(
                        Text(goal.name.prefix(1).uppercased())
                            .font(.system(size: 22, weight: .regular, design: .serif)).foregroundStyle(.white)
                    )
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(goal.name)
                            .font(.system(size: 15, weight: .semibold)).foregroundStyle(Color.warmInk).lineLimit(1)
                        if goal.isFavorite {
                            Image(systemName: "star.fill").font(.system(size: 12)).foregroundStyle(Color.warmAmber)
                        }
                    }
                    Text(paceText)
                        .font(.system(size: 12)).foregroundStyle(Color.warmInkMuted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(goal.progress * 100))%")
                        .font(.system(size: 18, weight: .regular, design: .serif)).foregroundStyle(Color.warmInk)
                    Button(action: onFavoriteToggle) {
                        Image(systemName: goal.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 16))
                            .foregroundStyle(goal.isFavorite ? Color.warmAmber : Color.warmInkMuted)
                    }
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(goal.trackColor).frame(height: 6)
                    RoundedRectangle(cornerRadius: 3).fill(goal.color)
                        .frame(width: geo.size.width * goal.progress, height: 6)
                }
            }
            .frame(height: 6)

            HStack {
                Text(formattedAmount(goal.current))
                    .font(.system(size: 12)).foregroundStyle(Color.warmInkSoft).monospacedDigit()
                Spacer()
                Text("of \(formattedAmount(goal.target))")
                    .font(.system(size: 12)).foregroundStyle(Color.warmInkMuted).monospacedDigit()
            }
        }
        .padding(16)
        .background(Color.warmSurface).cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.warmLine, lineWidth: 1))
        .contextMenu {
            Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog("Delete Goal", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this goal?")
        }
    }

    private var paceText: String {
        goal.progress >= 1.0 ? "Complete!" : goal.progress > 0.5 ? "On track" : "In progress"
    }

    private func formattedAmount(_ v: Double) -> String {
        let f = NumberFormatter()
        f.numberStyle = .currency; f.currencySymbol = "$"; f.maximumFractionDigits = 0
        return f.string(from: NSNumber(value: v)) ?? "$0"
    }
}

#Preview {
    NavigationStack { GoalsView(showAddGoalFlow: .constant(false)) }
}
