//
//  TipsListView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import SwiftUI

struct TipsListView: View {
    let tips: [Tip]
    @Binding var favorites: [String]
    var filterFavorites: Bool = false
    
    var body: some View {
        VStack(spacing: 20) {
            ForEach(filteredTips) { tip in
                TipCardView(tip: tip, isFavorite: favorites.contains(tip.id)) {
                    toggleFavorite(tip.id)
                }
            }
        }
    }
    
    private var filteredTips: [Tip] {
        filterFavorites ? tips.filter { favorites.contains($0.id) } : tips
    }
    
    private func toggleFavorite(_ id: String) {
        if favorites.contains(id) {
            favorites.removeAll { $0 == id }
        } else {
            favorites.append(id)
        }
    }
}

#Preview {
    @State var favorites = ["1"]
    
    return TipsListView(
        tips: [
            Tip(id: "1", title: "Reduce gastos", description: "Opción gratuita de entretenimiento."),
            Tip(id: "2", title: "Aumenta tus ahorros", description: "Incrementar tus ahorros en un 5%.")
        ],
        favorites: $favorites
    )
}
