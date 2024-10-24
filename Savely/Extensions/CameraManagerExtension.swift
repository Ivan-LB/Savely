//
//  CameraManagerExtension.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 21/10/24.
//

import Foundation
import AVFoundation

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation() else {
            print("Error: No se pudo obtener la imagen.")
            return
        }
        self.photoData = data
    }
}
