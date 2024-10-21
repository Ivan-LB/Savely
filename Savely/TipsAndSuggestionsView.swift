//
//  TipsAndSuggestionsView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI

struct TipsAndSuggestionsView: View {
    @State private var favorites: [String] = []
    
    let personalizedTips = [
        Tip(id: "1", title: "Reduce gastos en entretenimiento", description: "Considera opciones gratuitas de entretenimiento para alcanzar tu meta de ahorro más rápido."),
        Tip(id: "2", title: "Aumenta tus ahorros mensuales", description: "Incrementar tus ahorros en un 5% te ayudará a alcanzar tu meta de vacaciones antes de lo planeado."),
        Tip(id: "3", title: "Revisa tus suscripciones", description: "Cancelar suscripciones no utilizadas podría ahorrarte hasta $50 al mes.")
    ]
    
    let generalTips = [
        Tip(id: "4", title: "Crea un fondo de emergencia", description: "Ahorra el equivalente a 3-6 meses de gastos para emergencias."),
        Tip(id: "5", title: "Sigue la regla 50/30/20", description: "Destina 50% a necesidades, 30% a deseos y 20% a ahorros de tus ingresos."),
        Tip(id: "6", title: "Automatiza tus ahorros", description: "Configura transferencias automáticas a tu cuenta de ahorros cada mes.")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                VStack(alignment: .leading, spacing: 5) {
                    Text("Consejos y Sugerencias")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue)
                
                // Tabs Section
                TabsView(personalizedTips: personalizedTips, generalTips: generalTips, favorites: $favorites)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGray6))
    }
}

struct Tip: Identifiable {
    let id: String
    let title: String
    let description: String
}

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
        .padding(.horizontal,5)
    }
}

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

struct TipsAndSuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        TipsAndSuggestionsView()
    }
}
