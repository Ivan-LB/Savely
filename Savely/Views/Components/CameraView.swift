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
                Spacer()
                HStack {
                    Button(action: {
                        cameraManager.capturePhoto()
                    }) {
                        Image(systemName: "camera.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.photoData) { data in
            if let data = data {
                // Aquí puedes manejar la imagen capturada como quieras, por ejemplo, subirla o guardarla.
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

struct CameraPreview: UIViewControllerRepresentable {
    let cameraManager: CameraManager

    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        cameraManager.setPreviewLayer(to: viewController.view)
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
