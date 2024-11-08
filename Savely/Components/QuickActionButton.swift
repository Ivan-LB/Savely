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

    var body: some View {
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
        .background(backgroundColor)
        .cornerRadius(10)
    }
}

#Preview {
    QuickActionButton(iconName: "camera", label: Strings.Buttons.addExpenseButton, backgroundColor: .green)
}
