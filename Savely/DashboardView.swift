//
//  DashboardView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 16/10/24.
//

import SwiftUI
import Charts

struct DashboardView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Section
                VStack(alignment: .leading, spacing: 5) {
                    Text("Bienvenido a Savely")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("Tu compañero de ahorro")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue)

                // Overview Card
                VStack(spacing: 15) {
                    Text("Resumen de Ahorros")
                        .font(.title3)
                        .fontWeight(.bold)
                    ZStack {
                        Circle()
                            .trim(from: 0, to: 0.75)
                            .stroke(Color.green, lineWidth: 8)
                            .frame(width: 160, height: 160)
                            .rotationEffect(.degrees(-90))
                        Text("75%")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    Text("Meta Mensual")
                        .font(.subheadline)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 2)
                .padding(.horizontal)

                // Quick Actions
                HStack(spacing: 20) {
                    QuickActionButton(iconName: "camera", label: "Registrar Gasto", backgroundColor: .green)
                    QuickActionButton(iconName: "plus.circle", label: "Nueva Meta", backgroundColor: .green)
                }
                .padding(.horizontal)

                // Weekly Spending Chart
                VStack(alignment: .leading, spacing: 10) {
                    Text("Gastos Semanales")
                        .font(.title3)
                        .fontWeight(.bold)
                    Chart {
                        BarMark(
                            x: .value("Día", "Lun"),
                            y: .value("Gasto", 20)
                        )
                        BarMark(
                            x: .value("Día", "Mar"),
                            y: .value("Gasto", 45)
                        )
                        BarMark(
                            x: .value("Día", "Mié"),
                            y: .value("Gasto", 28)
                        )
                        BarMark(
                            x: .value("Día", "Jue"),
                            y: .value("Gasto", 80)
                        )
                        BarMark(
                            x: .value("Día", "Vie"),
                            y: .value("Gasto", 99)
                        )
                        BarMark(
                            x: .value("Día", "Sáb"),
                            y: .value("Gasto", 43)
                        )
                        BarMark(
                            x: .value("Día", "Dom"),
                            y: .value("Gasto", 50)
                        )
                    }
                    .frame(height: 200)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 2)
                .padding(.horizontal)

                // Tip of the Day Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .foregroundColor(.blue)
                        Text("Consejo del Día")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    Text("Establece metas pequeñas y alcanzables. ¡El éxito en pequeños objetivos te motivará a lograr metas más grandes!")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
                .shadow(radius: 2)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(UIColor.systemGray6))
    }
}

struct QuickActionButton: View {
    var iconName: String
    var label: String
    var backgroundColor: Color

    var body: some View {
        VStack {
            Image(systemName: iconName)
                .resizable()
                .frame(width: 24, height: 24)
                .foregroundColor(.white)
                .padding()
                .background(backgroundColor)
                .clipShape(Circle())
            Text(label)
                .font(.footnote)
                .foregroundColor(.white)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
