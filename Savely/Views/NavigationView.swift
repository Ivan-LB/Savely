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
                    Text(Strings.Tabs.dashboardTab)
                }

            GoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text(Strings.Tabs.goalsTab)
                }

            ExpenseTrackerView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text(Strings.Tabs.expensesTab)
                }

            ReportsView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text(Strings.Tabs.reportsTab)
                }

            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text(Strings.Tabs.profileTab)
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
