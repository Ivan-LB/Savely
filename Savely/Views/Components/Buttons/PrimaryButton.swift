//
//  PrimaryButton.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 15/11/24.
//

import SwiftUI

struct PrimaryButton: View {
    let action: () -> Void
    let text: String
    
    var body: some View {
        Button {
            action()
        } label: {
            Text(text)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .fontWeight(.bold)
                .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
        }
        .padding(.horizontal)
    }
}

#Preview {
    PrimaryButton(action: {
        print("Hola")
    }, text: "Hola")
}
