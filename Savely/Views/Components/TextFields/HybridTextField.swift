//
//  HybridTextField.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 14/11/24.
//

import SwiftUI

struct HybridTextField: View {
    @Binding var text: String
    let label: String
    @State private var isSecure: Bool = true
    var titleKey: String

    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
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
                        .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                )
                .background(Color(UIColor.systemGray6))
                .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
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
}
