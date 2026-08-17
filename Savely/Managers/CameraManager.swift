//
//  CameraManager.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 21/10/24.
//
//  Owns the AVCaptureSession behind the receipt scanner: permission,
//  configuration, the preview layer, torch, and a single still capture.
//  The still is delivered with its EXIF orientation set from an
//  `AVCaptureDevice.RotationCoordinator`, so OCR sees the receipt the way the
//  user held the phone (the old code never set the connection's rotation and
//  then dropped the orientation again before Vision — see docs/spikes).
//

import AVFoundation
import UIKit
import Observation

enum CameraError: Error, Equatable {
    /// The session is not configured/running (no permission, no camera,
    /// or the configuration is still in flight).
    case notReady
    /// A capture is already in progress.
    case busy
    /// AVFoundation reported a capture failure or produced no data.
    case captureFailed
}

@Observable
final class CameraManager: NSObject {
    /// False on devices without a back camera (the simulator) or when the
    /// user denied camera access — the view shows a message instead of a
    /// frozen black preview.
    private(set) var isCameraAvailable = true
    /// True once the session streams frames — the shutter is enabled only then.
    private(set) var isRunning = false
    private(set) var isTorchOn = false
    private(set) var hasTorch = false

    @ObservationIgnored let session = AVCaptureSession()
    @ObservationIgnored private let photoOutput = AVCapturePhotoOutput()
    @ObservationIgnored private let sessionQueue = DispatchQueue(label: "savely.camera.session")
    @ObservationIgnored private var videoDevice: AVCaptureDevice?
    @ObservationIgnored private var previewLayer: AVCaptureVideoPreviewLayer?
    @ObservationIgnored private var rotationCoordinator: AVCaptureDevice.RotationCoordinator?
    @ObservationIgnored private var rotationObservation: NSKeyValueObservation?
    @ObservationIgnored private var isConfigured = false
    /// The pending `capturePhoto()` caller. Guarded by `sessionQueue`.
    @ObservationIgnored var photoContinuation: CheckedContinuation<Data, Error>?

    // MARK: - Session lifecycle

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
                let running = self.session.isRunning
                DispatchQueue.main.async {
                    // Coming back from Settings after granting access lands here
                    // with `isCameraAvailable == false` from the earlier denial.
                    self.isCameraAvailable = true
                    self.isRunning = running
                    self.installRotationCoordinatorIfPossible()
                }
            }
        }
    }

    func stopSession() {
        setTorch(false)
        sessionQueue.async {
            if self.session.isRunning { self.session.stopRunning() }
            DispatchQueue.main.async { self.isRunning = false }
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

        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            markUnavailable("No back camera on this device.")
            return false
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            guard session.canAddInput(input) else {
                markUnavailable("Could not add the camera input.")
                return false
            }
            session.addInput(input)
        } catch {
            markUnavailable("Could not create the camera input: \(error)")
            return false
        }

        guard session.canAddOutput(photoOutput) else {
            markUnavailable("Could not add the photo output.")
            return false
        }
        session.addOutput(photoOutput)
        // Speed over maximum quality: a receipt is text at close range and
        // the user is waiting for the result.
        photoOutput.maxPhotoQualityPrioritization = .balanced

        videoDevice = device
        isConfigured = true
        DispatchQueue.main.async { self.hasTorch = device.hasTorch }
        return true
    }

    private func markUnavailable(_ reason: String) {
        print(reason)
        DispatchQueue.main.async { self.isCameraAvailable = false }
    }

    // MARK: - Preview

    func setPreviewLayer(to view: UIView) {
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        layer.frame = view.bounds
        previewLayer = layer
        view.layer.insertSublayer(layer, at: 0)
        installRotationCoordinatorIfPossible()
    }

    /// Keeps the preview filling the view when it is laid out (sheet vs
    /// full-screen, rotation).
    func layoutPreviewLayer(in view: UIView) {
        previewLayer?.frame = view.bounds
    }

    /// Once both the device and the preview layer exist, the coordinator
    /// keeps the preview upright and tells us the angle to stamp on captures.
    /// Main thread only (KVO on a UI-facing object).
    private func installRotationCoordinatorIfPossible() {
        guard rotationCoordinator == nil, let device = videoDevice, let previewLayer else { return }
        let coordinator = AVCaptureDevice.RotationCoordinator(device: device, previewLayer: previewLayer)
        rotationCoordinator = coordinator
        applyPreviewRotation(coordinator.videoRotationAngleForHorizonLevelPreview)
        rotationObservation = coordinator.observe(\.videoRotationAngleForHorizonLevelPreview, options: [.new]) { [weak self] coordinator, _ in
            self?.applyPreviewRotation(coordinator.videoRotationAngleForHorizonLevelPreview)
        }
    }

    private func applyPreviewRotation(_ angle: CGFloat) {
        guard let connection = previewLayer?.connection, connection.isVideoRotationAngleSupported(angle) else { return }
        connection.videoRotationAngle = angle
    }

    // MARK: - Torch

    func toggleTorch() {
        setTorch(!isTorchOn)
    }

    func setTorch(_ on: Bool) {
        guard let device = videoDevice, device.hasTorch else { return }
        sessionQueue.async {
            do {
                try device.lockForConfiguration()
                device.torchMode = on ? .on : .off
                device.unlockForConfiguration()
                DispatchQueue.main.async { self.isTorchOn = on }
            } catch {
                print("Torch unavailable: \(error)")
            }
        }
    }

    // MARK: - Capture

    /// Takes one still and returns its file data (JPEG/HEIF with EXIF
    /// orientation). Throws `.notReady` instead of crashing when the session
    /// never got configured, and `.busy` while a capture is in flight.
    func capturePhoto() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async {
                guard self.isConfigured, self.session.isRunning,
                      let connection = self.photoOutput.connection(with: .video), connection.isActive else {
                    continuation.resume(throwing: CameraError.notReady)
                    return
                }
                guard self.photoContinuation == nil else {
                    continuation.resume(throwing: CameraError.busy)
                    return
                }
                if let coordinator = self.rotationCoordinator {
                    let angle = coordinator.videoRotationAngleForHorizonLevelCapture
                    if connection.isVideoRotationAngleSupported(angle) { connection.videoRotationAngle = angle }
                }
                let settings = AVCapturePhotoSettings()
                settings.photoQualityPrioritization = .balanced
                self.photoContinuation = continuation
                self.photoOutput.capturePhoto(with: settings, delegate: self)
            }
        }
    }

    /// Called by the capture delegate (see CameraManagerExtension.swift).
    func finishCapture(with result: Result<Data, Error>) {
        sessionQueue.async {
            guard let continuation = self.photoContinuation else { return }
            self.photoContinuation = nil
            continuation.resume(with: result)
        }
    }
}
