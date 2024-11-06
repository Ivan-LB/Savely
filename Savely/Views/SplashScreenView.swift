//
//  SplashScreenView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 21/10/24.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var isSplashEnded = false
    
    var body: some View {
        ZStack {
            if isSplashEnded {
                // La pantalla principal de la app, reemplaza con la vista principal
                NavigationView()
            } else {
                VStack {
                    Image(systemName: "banknote.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .foregroundColor(.green)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                        .onAppear {
                            isAnimating = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                withAnimation {
                                    isSplashEnded = true
                                }
                            }
                        }
                    
                    Text("Savely")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .opacity(isAnimating ? 1.0 : 0.5)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isAnimating)
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
