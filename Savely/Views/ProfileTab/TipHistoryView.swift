//
//  TipHistoryView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/11/24.
//

import SwiftUI
import SwiftData
import MarkdownUI

struct TipHistoryView: View {
    @Query(sort: \TipModel.date, order: .reverse) var tips: [TipModel]
    
    var body: some View {
        List(tips) { tip in
            VStack(alignment: .leading, spacing: 5) {
                Markdown(tip.content)
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
}
