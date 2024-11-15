//
//  CameraPreview.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 23/10/24.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let cameraManager: CameraManager

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        cameraManager.setPreviewLayer(to: view)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // No es necesario actualizar nada aquí por ahora
    }
}
