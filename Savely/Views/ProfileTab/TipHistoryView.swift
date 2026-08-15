//
//  TipHistoryView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/11/24.
//

import SwiftUI
import SwiftData

struct TipHistoryView: View {
    @Query(sort: \TipModel.date, order: .reverse) var tips: [TipModel]

    var body: some View {
        List(tips) { tip in
            VStack(alignment: .leading, spacing: 5) {
                // Native markdown (replaced MarkdownUI): tips are short
                // OpenAI strings — inline styling (bold/italic/links) is all
                // they use, so AttributedString's inline parser is enough.
                Text(attributedTip(tip.content))
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                Text(tip.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            .padding(.vertical, 5)
        }
        .listStyle(PlainListStyle())
        .navigationTitle(Strings.Profile.tipsHistoryTitle)
    }

    private func attributedTip(_ content: String) -> AttributedString {
        (try? AttributedString(
            markdown: content,
            options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        )) ?? AttributedString(content)
    }
}
