//
//  CameraManagerExtension.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 21/10/24.
//

import AVFoundation
import Vision

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let data = photo.fileDataRepresentation() {
            DispatchQueue.main.async {
                self.photoData = data
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard !isProcessingFrame else { return }
        isProcessingFrame = true

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessingFrame = false
            return
        }

        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([self.rectangleDetectionRequest])
                if let results = self.rectangleDetectionRequest.results as? [VNRectangleObservation], let rectangle = results.first {
                    DispatchQueue.main.async {
                        self.isRectangleDetected = true
                        self.detectedRectangle = rectangle
                    }
                } else {
                    DispatchQueue.main.async {
                        self.isRectangleDetected = false
                        self.detectedRectangle = nil
                    }
                }
            } catch {
                print("Error al realizar la solicitud de detección de rectángulos: \(error)")
            }

            self.isProcessingFrame = false
        }
    }
}
