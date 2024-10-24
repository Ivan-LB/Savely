//
//  CameraManager.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 21/10/24.
//

import AVFoundation
import UIKit

class CameraManager: NSObject, ObservableObject {
    private let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    @Published var photoData: Data? = nil
    
    func startSession() {
        // Configurar la sesión de captura
        session.beginConfiguration()
        
        // Configurar el dispositivo de entrada (cámara)
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Error: No se pudo configurar la cámara.")
            return
        }
        
        // Añadir entrada y salida a la sesión
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        session.commitConfiguration()
        session.startRunning()
    }
    
    func stopSession() {
        session.stopRunning()
    }
    
    func setPreviewLayer(to view: UIView) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        view.layer.addSublayer(previewLayer!)
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }
}
