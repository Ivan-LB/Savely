//
//  TipCardView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import SwiftUI

struct TipCardView: View {
    let tip: Tip
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(tip.title)
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "star.fill" : "bookmark.circle")
                        .foregroundColor(isFavorite ? .yellow : .gray)
                }
            }
            Text(tip.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(10)
        .shadow(radius: 2)
        .padding(.horizontal)
    }
}

#Preview {
    TipCardView(
        tip: Tip(id: "1", title: "Aumenta tus ahorros", description: "Incrementa tus ahorros en un 5%."),
        isFavorite: true,
        onToggleFavorite: {}
    )
}
