//
//  TextRecognizer.swift
//  Savely
//
//  Created by Aldair Salazar on 11/13/24.
//

import Vision
import UIKit

class TextRecognizer {
    
    // Esta función acepta una UIImage y un closure que devuelve el texto reconocido
    func recognizeText(in image: UIImage, completion: @escaping (String?) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(nil)
            return
        }

        let request = VNRecognizeTextRequest { (request, error) in
            if let error = error {
                print("Error de reconocimiento de texto: \(error)")
                completion(nil)
                return
            }
            
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                completion(nil)
                return
            }

            // Recopilar todo el texto reconocido en una sola cadena
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")

            completion(recognizedText.isEmpty ? nil : recognizedText)
        }

        request.recognitionLevel = .accurate

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                print("Error al realizar la solicitud de reconocimiento de texto: \(error)")
                completion(nil)
            }
        }
    }
}

