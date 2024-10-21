//
//  GoalsView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI

struct GoalsView: View {
    let goals = [
        Goal(id: 1, name: "Vacaciones", current: 2000, target: 5000, color: .green),
        Goal(id: 2, name: "Nuevo Teléfono", current: 300, target: 1000, color: .blue),
        Goal(id: 3, name: "Fondo de Emergencia", current: 1500, target: 3000, color: .yellow)
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                VStack(alignment: .leading, spacing: 5) {
                    Text("Tus Metas de Ahorro")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue)
                
                // Add New Goal Button
                Button(action: {
                    // Action for adding a new goal
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                            .foregroundColor(.white)
                            .font(.title)
                        Text(Strings.Buttons.newGoalButton)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
                // Goals List
                ForEach(goals) { goal in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(goal.color)
                            Text(goal.name)
                                .font(.title3)
                                .fontWeight(.bold)
                        }
                        ProgressView(value: goal.progress)
                            .accentColor(goal.color)
                            .frame(height: 10)
                            .padding(.vertical, 5)
                        HStack {
                            Text("$\(goal.current, specifier: "%.2f") / $\(goal.target, specifier: "%.2f")")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(goal.progress * 100))%")
                                .font(.subheadline)
                                .fontWeight(.bold)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white)
                    .cornerRadius(10)
                    .shadow(radius: 2)
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGray6))
    }
}

struct GoalsView_Previews: PreviewProvider {
    static var previews: some View {
        GoalsView()
    }
}
