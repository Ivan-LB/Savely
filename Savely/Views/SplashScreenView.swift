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
                ContentView()
            } else {
                ZStack {
                    Color("backgroundColor")
                    VStack {
                        Image("AppUtilityIcon")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .opacity(isAnimating ? 1.0 : 0.5)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .foregroundStyle(Color.primaryGreen)
                            .animation(.easeInOut(duration: 1.5), value: isAnimating)
                            .onAppear {
                                isAnimating = true
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    withAnimation {
                                        isSplashEnded = true
                                    }
                                }
                            }

                        
                        Text(Strings.SplashScreen.savelyAppTitle)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(Color.primaryGreen)
                            .opacity(isAnimating ? 1.0 : 0.5)
                            .scaleEffect(isAnimating ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 1.5), value: isAnimating)
                    }
                    .transition(.opacity)
                }
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
