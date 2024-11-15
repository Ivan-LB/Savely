//
//  CustomTextfield.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 15/11/24.
//

import SwiftUI

struct CustomTextfield: View {
    let placeholder: String
    @Binding var value: String
    
    var body: some View {
        TextField(placeholder, text: $value)
            .padding()
            .autocorrectionDisabled()
            .background(
                RoundedRectangle(cornerRadius: UIConstants.UICornerRadius.cornerRadius)
                    .stroke(Color.black, lineWidth: UIConstants.UILineWidth.lineWidth)
            )
    }
}

#Preview {
    CustomTextfield(placeholder: Strings.Authentication.fullNamePlaceholder, value: .constant("Hola"))
}
