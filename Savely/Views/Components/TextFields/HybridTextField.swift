//
//  HybridTextField.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 14/11/24.
//

import SwiftUI

struct HybridTextField: View {
    @Binding var text: String
    @State private var isSecure: Bool = true
    var titleKey: String

    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isSecure {
                    SecureField(titleKey, text: $text)
                        .autocorrectionDisabled()
                } else {
                    TextField(titleKey, text: $text)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                }
            }
            .padding(.trailing, 32)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: UIConstants.UICornerRadius.cornerRadius)
                    .stroke(Color.black, lineWidth: 1)
            )
            Button(action: {
                isSecure.toggle()
            }) {
                Image(systemName: self.isSecure ? "eye.slash" : "eye")
                    .accentColor(.gray)
            }
            .padding(.trailing, 16)
        }
    }
}
