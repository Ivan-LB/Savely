//
//  GoalEditSheet.swift
//  Savely
//
//  Edit an existing goal: name, target, color (all thirteen), deadline
//  (optional), payday auto-move. One explicit Save; validation errors are
//  shown, never swallowed. Presented as a sheet from GoalDetailView's
//  pencil and from the Dashboard hero card's pencil.
//

import SwiftUI
import SwiftData

struct GoalEditSheet: View {
    @Bindable var goal: GoalModel
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draft: GoalEditDraft
    @State private var targetText: String
    @State private var autoMoveText: String
    @State private var color: GoalColor
    @State private var errorMessage: String?
    @ScaledMetric(relativeTo: .body) private var targetFieldWidth: CGFloat = 110
    @ScaledMetric(relativeTo: .body) private var autoFieldWidth: CGFloat = 90

    init(goal: GoalModel) {
        self.goal = goal
        let deadline = goal.deadline ?? Calendar.current.date(byAdding: .month, value: 6, to: Date()) ?? Date()
        _draft = State(initialValue: GoalEditDraft(
            name: goal.name,
            target: goal.target,
            hasDeadline: goal.deadline != nil,
            deadline: deadline,
            autoMoveEnabled: goal.autoMoveEnabled,
            autoMoveAmount: goal.autoMoveAmount
        ))
        _targetText = State(initialValue: Self.plainNumber(goal.target))
        _autoMoveText = State(initialValue: Self.plainNumber(goal.autoMoveAmount))
        _color = State(initialValue: GoalColor(rawValue: goal.colorRawValue) ?? .green)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    // — Name & target —
                    card {
                        fieldRow(label: "Name") {
                            TextField("Goal name", text: $draft.name)
                                .warmFont(15)
                                .foregroundStyle(Color.warmInk)
                                .multilineTextAlignment(.trailing)
                        }
                        WarmDivider()
                        fieldRow(label: "Target") {
                            HStack(spacing: 2) {
                                Text("$").foregroundStyle(Color.warmInkMuted)
                                TextField("0", text: $targetText)
                                    .keyboardType(.decimalPad)
                                    .warmFont(15)
                                    .foregroundStyle(Color.warmInk)
                                    .monospacedDigit()
                                    .multilineTextAlignment(.trailing)
                                    .frame(width: targetFieldWidth)
                                    .onChange(of: targetText) { draft.target = parseAmount(targetText) ?? 0 }
                            }
                        }
                    }

                    // — Color —
                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("Color")
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                            ForEach(GoalColor.allCases) { gc in
                                let isOn = color == gc
                                Button(action: { color = gc }) {
                                    Circle()
                                        .fill(gc.color)
                                        .frame(width: 36, height: 36)
                                        .overlay(Circle().stroke(Color.warmSurface, lineWidth: isOn ? 3 : 0))
                                        .overlay(Circle().stroke(isOn ? Color.warmInk : Color.clear, lineWidth: 1.5))
                                }
                                .buttonStyle(.plain)
                                .accessibilityLabel(gc.displayName)
                                .accessibilityAddTraits(isOn ? .isSelected : [])
                            }
                        }
                        .padding(14)
                        .background(Color.warmSurface)
                        .cornerRadius(16)
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))
                    }

                    // — Deadline —
                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("Timing")
                        card {
                            toggleRow("Target date", isOn: $draft.hasDeadline)
                            if draft.hasDeadline {
                                WarmDivider()
                                fieldRow(label: "By") {
                                    DatePicker("Target date", selection: $draft.deadline, in: Date()..., displayedComponents: .date)
                                        .labelsHidden()
                                        .tint(Color.warmGreen)
                                }
                            }
                        }
                    }

                    // — Auto-move —
                    VStack(alignment: .leading, spacing: 10) {
                        sectionLabel("Payday")
                        card {
                            toggleRow("Auto-move on payday", isOn: $draft.autoMoveEnabled)
                            if draft.autoMoveEnabled {
                                WarmDivider()
                                fieldRow(label: "Amount each payday") {
                                    HStack(spacing: 2) {
                                        Text("$").foregroundStyle(Color.warmInkMuted)
                                        TextField("0", text: $autoMoveText)
                                            .keyboardType(.decimalPad)
                                            .warmFont(15)
                                            .foregroundStyle(Color.warmInk)
                                            .monospacedDigit()
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: autoFieldWidth)
                                            .onChange(of: autoMoveText) { draft.autoMoveAmount = parseAmount(autoMoveText) ?? 0 }
                                    }
                                }
                            }
                        }
                    }

                    Spacer(minLength: 16)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .background(Color.warmBg)
            .navigationTitle("Edit goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.warmInkSoft)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.semibold).foregroundStyle(Color.warmGreen)
                }
            }
            .alert("Can't save yet", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .honorsReduceMotion()
    }

    // MARK: - Save

    private func save() {
        if let error = GoalEditValidation.firstError(in: draft, current: goal.current) {
            errorMessage = error.localizedDescription
            return
        }
        goal.name = draft.trimmedName
        goal.target = draft.target
        goal.colorRawValue = color.rawValue
        goal.deadline = draft.hasDeadline ? draft.deadline : nil
        goal.autoMoveEnabled = draft.autoMoveEnabled
        goal.autoMoveAmount = draft.autoMoveEnabled ? draft.autoMoveAmount : goal.autoMoveAmount
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Couldn't save the goal. Please try again."
        }
    }

    // MARK: - Pieces

    private func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background(Color.warmSurface)
            .cornerRadius(16)
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.warmLine, lineWidth: 1))
    }

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .warmFont(11, weight: .semibold)
            .foregroundStyle(Color.warmInkMuted)
            .tracking(0.8)
            .padding(.leading, 4)
            .accessibilityAddTraits(.isHeader)
    }

    private func fieldRow<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 16) {
            Text(label)
                .warmFont(14, weight: .medium)
                .foregroundStyle(Color.warmInk)
            Spacer(minLength: 12)
            content()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private func toggleRow(_ title: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            Text(title).warmFont(14, weight: .medium).foregroundStyle(Color.warmInk)
        }
        .tint(Color.warmGreen)
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    private static func plainNumber(_ value: Double) -> String {
        value == value.rounded() ? String(Int(value)) : String(value)
    }
}
