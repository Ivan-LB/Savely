//
//  MainNavigationView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI

struct MainNavigationView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(Strings.Tabs.dashboardTab)
                }
                .toolbarBackground(.visible, for: .tabBar)

            GoalsView()
                .tabItem {
                    Image(systemName: "target")
                    Text(Strings.Tabs.goalsTab)
                }
                .toolbarBackground(.visible, for: .tabBar)

            ExpenseTrackerView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text(Strings.Tabs.expensesTab)
                }
                .toolbarBackground(.visible, for: .tabBar)

            //ReportsView()
            IncomesTrackerView()
                .tabItem {
                    Image(systemName: "dollarsign.circle.fill")
                    Text(Strings.Tabs.incomesTab)
                }
                .toolbarBackground(.visible, for: .tabBar)

            ProfileView()
                .tabItem {
                    Image(systemName: "person.crop.circle")
                    Text(Strings.Tabs.profileTab)
                }
                .toolbarBackground(.visible, for: .tabBar)
        }
        .accentColor(.green)
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainNavigationView()
    }
}
