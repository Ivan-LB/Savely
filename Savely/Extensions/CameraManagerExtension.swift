//
//  CameraManagerExtension.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 21/10/24.
//

import AVFoundation

// MARK: - AVCapturePhotoCaptureDelegate
extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishProcessingPhoto photo: AVCapturePhoto,
                     error: Error?) {
        if let error {
            finishCapture(with: .failure(error))
            return
        }
        guard let data = photo.fileDataRepresentation() else {
            finishCapture(with: .failure(CameraError.captureFailed))
            return
        }
        finishCapture(with: .success(data))
    }

    /// Fires even when `didFinishProcessingPhoto` never does (rare capture
    /// pipeline errors); `finishCapture` ignores a second resume, so this
    /// only matters when the continuation is still pending.
    func photoOutput(_ output: AVCapturePhotoOutput,
                     didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings,
                     error: Error?) {
        if let error {
            finishCapture(with: .failure(error))
        }
    }
}
