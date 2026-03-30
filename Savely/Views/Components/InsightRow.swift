//
//  InsightRow.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 15/03/26.
//

import SwiftUI

struct InsightRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let accessory: AccessoryType
    
    enum AccessoryType {
        case chevron
        case badge(String)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(iconColor)
            }
            
            // Title and Subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Accessory
            accessoryView
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var accessoryView: some View {
        switch accessory {
            case .chevron:
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
            case .badge(let text):
                HStack(spacing: 4) {
                    Image(systemName: "doc.fill")
                        .font(.caption)
                    Text(text)
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundStyle(iconColor)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(iconColor.opacity(0.1))
                .cornerRadius(8)
            }
    }
}

#Preview {
    InsightRow(
        icon: "lightbulb.fill",
        iconColor: Color(red: 0.3, green: 0.5, blue: 0.4),
        title: "Tip History",
        subtitle: "3 new saving tips",
        accessory: .chevron
    )
}
