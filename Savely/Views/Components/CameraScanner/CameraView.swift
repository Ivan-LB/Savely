//
//  CameraView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 21/10/24.
//

import SwiftUI
import Vision
import UIKit

struct CameraView: View {
    @ObservedObject var viewModel: CameraViewModel
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            CameraPreview(cameraManager: viewModel.cameraManager)
                .edgesIgnoringSafeArea(.all)
            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        viewModel.capturePhoto()
                    }) {
                        Image(systemName: "camera.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 30)
                    Spacer()
                }
            }

            // Mostrar la vista de confirmación si se detecta un total
            if viewModel.showConfirmation {
                TotalConfirmationView(
                    detectedTotal: viewModel.detectedTotal,
                    alternativeTotals: viewModel.alternativeTotals,
                    onConfirm: { total in
                        viewModel.confirmTotal(total)
                    },
                    onRetake: {
                        viewModel.retakePhoto()
                    }
                )
                .frame(width: 300, height: 400)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: UIConstants.UIShadow.shadowBig)
            }
        }
        .onAppear {
            viewModel.startSession()
            // Asignar el closure para dismiss
            viewModel.dismissCameraView = {
                presentationMode.wrappedValue.dismiss()
            }
        }
        .onDisappear {
            viewModel.stopSession()
        }
    }
}
