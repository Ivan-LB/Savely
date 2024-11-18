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
        TipModel(id: "1", title: "Reduce gastos en entretenimiento", description: "Considera opciones gratuitas de entretenimiento para alcanzar tu meta de ahorro más rápido."),
        TipModel(id: "2", title: "Aumenta tus ahorros mensuales", description: "Incrementar tus ahorros en un 5% te ayudará a alcanzar tu meta de vacaciones antes de lo planeado."),
        TipModel(id: "3", title: "Revisa tus suscripciones", description: "Cancelar suscripciones no utilizadas podría ahorrarte hasta $50 al mes.")
    ]
    
    let generalTips = [
        TipModel(id: "4", title: "Crea un fondo de emergencia", description: "Ahorra el equivalente a 3-6 meses de gastos para emergencias."),
        TipModel(id: "5", title: "Sigue la regla 50/30/20", description: "Destina 50% a necesidades, 30% a deseos y 20% a ahorros de tus ingresos."),
        TipModel(id: "6", title: "Automatiza tus ahorros", description: "Configura transferencias automáticas a tu cuenta de ahorros cada mes.")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                VStack(alignment: .leading, spacing: 5) {
                    Text(Strings.DashboardTab.tipsAndSuggestionsTitle)
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

struct TipsAndSuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        TipsAndSuggestionsView()
    }
}
