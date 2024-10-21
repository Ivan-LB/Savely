//
//  NavigationView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI

struct NavigationView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Dashboard")
                }

            GoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text("Metas")
                }

            ExpenseTrackerView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Gastos")
                }

            ReportsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Reportes")
                }

            TipsAndSuggestionsView()
                .tabItem {
                    Image(systemName: "lightbulb.fill")
                    Text("Consejos")
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text("Perfil")
                }
        }
        .accentColor(.blue)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView()
    }
}
