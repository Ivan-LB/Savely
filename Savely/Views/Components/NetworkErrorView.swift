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

            Text("Limited Connectivity")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("Your device is offline. Features like Tips may not work, but the app is fully functional offline.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
                .padding(.horizontal)

            Button(action: {
                isPresented = false
            }) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .fontWeight(.bold)
                    .background(Color("primaryGreen"))
                    .foregroundColor(.white)
                    .cornerRadius(10)
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
