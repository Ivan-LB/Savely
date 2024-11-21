//
//  TipsAndSuggestionsView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI
import SwiftData
import MarkdownUI

struct TipsAndSuggestionsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = TipsAndSuggestionViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "lightbulb")
                    .foregroundColor(.blue)
                Text(Strings.DashboardTab.tipOfTheDayTitle)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            if let tip = viewModel.currentTip {
                Markdown(tip.content)
                    .font(.body)
                    .foregroundColor(.secondary)
            } else {
                Text(Strings.DashboardTab.loadingTipLabel)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.green.opacity(0.1))
        .cornerRadius(UIConstants.UICornerRadius.cornerRadiusMedium)
        .shadow(radius: UIConstants.UIShadow.shadow)
        .onAppear {
            if viewModel.modelContext == nil {
                viewModel.setModelContext(modelContext)
            }
        }
    }
}
