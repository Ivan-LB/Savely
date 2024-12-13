//
//  NetworkErrorView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 12/12/24.
//

import SwiftUI

struct NetworkErrorView: View {
    @Binding var isPresented: Bool

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.yellow)

            Text(Strings.NetworkError.limitedConnectionHeader)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(Strings.NetworkError.deviceNotConnectedToInternetBody)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)

            Button(action: {
                isPresented = false
            }) {
                Text(Strings.Buttons.continueButton)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .fontWeight(.bold)
                    .background(Color("primaryGreen"))
                    .foregroundColor(.white)
                    .cornerRadius(UIConstants.UICornerRadius.cornerRadius)
            }
            .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    NetworkErrorView(isPresented: .constant(true))
}
