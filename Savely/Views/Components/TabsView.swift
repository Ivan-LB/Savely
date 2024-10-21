//
//  TabsView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import SwiftUI

struct TabsView: View {
    let personalizedTips: [Tip]
    let generalTips: [Tip]
    @Binding var favorites: [String]
    
    @State private var selectedTab: String = "personalized"
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Picker("Select Tab", selection: $selectedTab) {
                Text("Personalizados").tag("personalized")
                Text("Generales").tag("general")
                Text("Favoritos").tag("favorites")
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            if selectedTab == "personalized" {
                TipsListView(tips: personalizedTips, favorites: $favorites)
            } else if selectedTab == "general" {
                TipsListView(tips: generalTips, favorites: $favorites)
            } else if selectedTab == "favorites" {
                TipsListView(tips: personalizedTips + generalTips, favorites: $favorites, filterFavorites: true)
            }
        }
        .padding(.horizontal, 5)
    }
}

#Preview {
    @State var favorites = ["1"]
    
    return TabsView(
        personalizedTips: [
            Tip(id: "1", title: "Reduce gastos", description: "Opción gratuita de entretenimiento."),
            Tip(id: "2", title: "Aumenta tus ahorros", description: "Incrementar tus ahorros en un 5%.")
        ],
        generalTips: [
            Tip(id: "3", title: "Fondo de emergencia", description: "Ahorra el equivalente a 3-6 meses."),
            Tip(id: "4", title: "Automatiza ahorros", description: "Transferencias automáticas mensuales.")
        ],
        favorites: $favorites
    )
}
