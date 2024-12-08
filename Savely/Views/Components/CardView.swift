//
//  CardView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import SwiftUI

struct CardView<Content: View>: View {
    let content: Content
    
    // Inicializador que recibe un @ViewBuilder para personalizar el contenido
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        VStack {
            content
        }
        .background(Color("cardBackgroundColor"))
        .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
        .shadow(radius: UIConstants.UIShadow.shadow)
        .padding(.horizontal)
    }
}

#Preview {
    CardView {
        Text(Strings.DashboardTab.monthlyGoalLabel)
    }
}
