//
//  QuickActionButton.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 20/10/24.
//

import SwiftUI

struct QuickActionButton: View {
    var iconName: String
    var label: String
    var backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: {
            action()
        }, label: {
            VStack {
                Image(systemName: iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.white)
                Text(label)
                    .font(.footnote)
                    .foregroundStyle(.white)
            }
            .padding()
            .frame(maxWidth: .infinity, minHeight: 50)
            .background(backgroundColor)
            .cornerRadius(UIConstants.UICornerRadius.cornerRadiusMedium)
        })
    }
}

#Preview {
    QuickActionButton(iconName: "camera", label: "Add Expense", backgroundColor: Color.red, action: {
        print("Button pressed")
    })
}
