//
//  WeeklyInsights.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 15/03/26.
//

import SwiftUI

struct WeeklyInsightsView: View {
    @StateObject private var viewModel = ProfileViewModel()
    
    var body: some View {
        // Weekly Insights Section
        VStack(alignment: .leading, spacing: 12) {
            Text("WEEKLY INSIGHTS")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            
            Button(action: viewModel.generateWeeklyReportPDF) {
                InsightRow(
                    icon: "chart.bar.fill",
                    iconColor: Color(red: 0.3, green: 0.5, blue: 0.4),
                    title: "Weekly Report",
                    subtitle: "Ready for review",
                    accessory: .badge("PDF")
                )
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
            
            NavigationLink(destination: TipHistoryView()) {
                TipHistoryRow(newTipsCount: viewModel.newTipsCount)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal)
        }
    }
}

// MARK: - Convenience Wrappers
struct WeeklyReportRow: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            InsightRow(
                icon: "chart.bar.fill",
                iconColor: Color(red: 0.3, green: 0.5, blue: 0.4),
                title: "Weekly Report",
                subtitle: "Ready for review",
                accessory: .badge("PDF")
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TipHistoryRow: View {
    let newTipsCount: Int
    
    var body: some View {
        InsightRow(
            icon: "lightbulb.fill",
            iconColor: Color(red: 0.3, green: 0.5, blue: 0.4),
            title: "Tip History",
            subtitle: "\(newTipsCount) new saving tips",
            accessory: .chevron
        )
    }
}

#Preview {
    WeeklyInsightsView()
}
