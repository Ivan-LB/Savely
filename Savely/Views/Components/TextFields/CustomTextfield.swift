//
//  CustomTextfield.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 15/11/24.
//

import SwiftUI

struct CustomTextfield: View {
    let label: String
    let placeholder: String
    @Binding var value: String
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(label)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
            TextField(placeholder, text: $value)
                .padding(16)
                .font(.body)
                .autocorrectionDisabled()
                .keyboardType(.emailAddress)
                .background(
                    RoundedRectangle(cornerRadius: UIConstants.UICornerRadius.cornerRadius)
                        .stroke(Color(UIColor.systemGray4), lineWidth: UIConstants.UILineWidth.lineWidth)
                )
                .background(Color(.systemGray6))
        }
    }
}

#Preview {
    CustomTextfield(label: "Hello", placeholder: Strings.Authentication.fullNamePlaceholder, value: .constant("Hola"))
}
