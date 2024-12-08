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
                    .foregroundColor(.white)
                Text(label)
                    .font(.footnote)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color("primaryGreen"))
            .frame(width: .infinity, height: .infinity)
            .cornerRadius(UIConstants.UICornerRadius.cornerRadiusMedium)
        })
    }
}

#Preview {
    QuickActionButton(iconName: "camera", label: Strings.Buttons.addExpenseButton, action: {
        print("Hola")
    })
}
