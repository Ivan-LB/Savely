//
//  CameraManager.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 21/10/24.
//

import AVFoundation
import Vision
import UIKit

class CameraManager: NSObject, ObservableObject {
    @Published var photoData: Data?
    @Published var isRectangleDetected: Bool = false
    @Published var detectedRectangle: VNRectangleObservation?

    private let session = AVCaptureSession()
    private var photoOutput = AVCapturePhotoOutput()
    private var videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "session_queue")
    private var previewLayer: AVCaptureVideoPreviewLayer?

    let rectangleDetectionRequest: VNDetectRectanglesRequest = {
        let request = VNDetectRectanglesRequest()
        request.maximumObservations = 1
        request.minimumConfidence = 0.8
        request.minimumAspectRatio = 0.3
        request.maximumAspectRatio = 1.0
        return request
    }()

    var isProcessingFrame = false

    func startSession() {
        sessionQueue.async {
            self.configureSession()
            self.session.startRunning()
        }
    }

    func stopSession() {
        sessionQueue.async {
            self.session.stopRunning()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .photo

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("No se pudo acceder a la cámara trasera.")
            return
        }

        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
            } else {
                print("No se pudo agregar entrada de cámara a la sesión.")
                return
            }
        } catch {
            print("Error al crear entrada de cámara: \(error)")
            return
        }

        if session.canAddOutput(photoOutput) {
            session.addOutput(photoOutput)
        } else {
            print("No se pudo agregar salida de foto a la sesión.")
            return
        }

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video_output_queue"))
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        } else {
            print("No se pudo agregar salida de video a la sesión.")
            return
        }

        session.commitConfiguration()
    }

    func setPreviewLayer(to view: UIView) {
        previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        view.layer.insertSublayer(previewLayer!, at: 0)
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}
