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

    /// False on devices without a back camera (the simulator) or when the
    /// user denied camera access — the view shows a message instead of a
    /// frozen black preview.
    @Published var isCameraAvailable = true
    private var isConfigured = false

    func startSession() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            guard let self else { return }
            guard granted else {
                DispatchQueue.main.async { self.isCameraAvailable = false }
                return
            }
            self.sessionQueue.async {
                guard self.configureSessionIfNeeded() else { return }
                if !self.session.isRunning { self.session.startRunning() }
            }
        }
    }

    func stopSession() {
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    /// Configures the session exactly once. Every exit path commits the
    /// configuration — `startRunning()` between begin/commit is a crash.
    /// Returns false when there is nothing to run (no camera).
    @discardableResult
    private func configureSessionIfNeeded() -> Bool {
        if isConfigured { return true }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        session.sessionPreset = .photo

        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("No back camera on this device.")
            DispatchQueue.main.async { self.isCameraAvailable = false }
            return false
        }

        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            guard session.canAddInput(videoDeviceInput) else {
                print("Could not add the camera input.")
                DispatchQueue.main.async { self.isCameraAvailable = false }
                return false
            }
            session.addInput(videoDeviceInput)
        } catch {
            print("Could not create the camera input: \(error)")
            DispatchQueue.main.async { self.isCameraAvailable = false }
            return false
        }

        guard session.canAddOutput(photoOutput) else {
            print("Could not add the photo output.")
            DispatchQueue.main.async { self.isCameraAvailable = false }
            return false
        }
        session.addOutput(photoOutput)

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "video_output_queue"))
        guard session.canAddOutput(videoOutput) else {
            print("Could not add the video output.")
            DispatchQueue.main.async { self.isCameraAvailable = false }
            return false
        }
        session.addOutput(videoOutput)
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]

        isConfigured = true
        return true
    }

    func setPreviewLayer(to view: UIView) {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        previewLayer = layer
        view.layer.insertSublayer(layer, at: 0)
    }

    /// Keeps the preview filling the view when it is laid out (sheet vs
    /// full-screen, rotation).
    func layoutPreviewLayer(in view: UIView) {
        previewLayer?.frame = view.bounds
    }

    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}
