import SwiftUI

struct MoneyView: View {
    @State private var selectedSegment = 0

    var body: some View {
        VStack(spacing: 0) {
            // Segmented control header
            Picker("", selection: $selectedSegment) {
                Text("Expenses").tag(0)
                Text("Income").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.warmBg)

            // Content (keep both live to preserve @StateObject VMs)
            ZStack {
                ExpenseTrackerView().opacity(selectedSegment == 0 ? 1 : 0)
                IncomesTrackerView().opacity(selectedSegment == 1 ? 1 : 0)
            }
        }
        .background(Color.warmBg)
        .animation(.easeInOut(duration: 0.18), value: selectedSegment)
    }
}

#Preview { MoneyView() }
