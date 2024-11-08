//
//  CameraView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 21/10/24.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ZStack {
            CameraPreview(cameraManager: cameraManager)
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
                        cameraManager.capturePhoto()
                    }) {
                        Image(systemName: "camera.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(cameraManager.isRectangleDetected ? .white : .gray)
                    }
                    .padding(.bottom, 30)
                    .disabled(!cameraManager.isRectangleDetected)
                    Spacer()
                }
            }

            // Mostrar superposición del rectángulo detectado
            if let rectangle = cameraManager.detectedRectangle {
                RectangleOverlay(rectangle: rectangle)
                    .stroke(Color.green, lineWidth: 2)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.photoData) { data in
            if let data = data, let image = UIImage(data: data) {
                // Preprocesar imagen y realizar OCR
                let preprocessedImage = preprocessImage(image)
                recognizeText(in: preprocessedImage)
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
