//
//  OCRUtilities.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 23/10/24.
//

import UIKit
import Vision
import CoreImage
import CoreImage.CIFilterBuiltins

func preprocessImage(_ image: UIImage) -> UIImage {
    guard let ciImage = CIImage(image: image) else { return image }

    // Convertir a escala de grises
    let grayscale = ciImage.applyingFilter("CIPhotoEffectMono")

    // Ajustar el contraste
    let adjustedContrast = grayscale.applyingFilter("CIColorControls", parameters: [
        kCIInputContrastKey: 1.5
    ])

    // Aplicar reducción de ruido
    let noiseReduction = adjustedContrast.applyingFilter("CINoiseReduction", parameters: [
        "inputNoiseLevel": 0.02,
        "inputSharpness": 0.4
    ])

    // Convertir de CIImage a UIImage
    let context = CIContext()
    if let cgImage = context.createCGImage(noiseReduction, from: noiseReduction.extent) {
        return UIImage(cgImage: cgImage)
    }

    return image
}

func recognizeText(in image: UIImage) {
    guard let cgImage = image.cgImage else { return }

    let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

    let request = VNRecognizeTextRequest { (request, error) in
        if let error = error {
            print("Error al reconocer texto: \(error.localizedDescription)")
            return
        }

        guard let observations = request.results as? [VNRecognizedTextObservation] else { return }

        var recognizedText = ""
        for observation in observations {
            guard let topCandidate = observation.topCandidates(1).first else { continue }
            recognizedText += topCandidate.string + "\n"
        }

        // Procesar el texto reconocido
        print("Texto reconocido:\n\(recognizedText)")

        // Extraer artículos y precios
        extractItemsAndPrices(from: recognizedText)
    }

    request.recognitionLevel = .accurate
    request.usesLanguageCorrection = false // Puedes ajustar esto según tus necesidades

    DispatchQueue.global(qos: .userInitiated).async {
        do {
            try requestHandler.perform([request])
        } catch {
            print("Error al realizar la solicitud de reconocimiento: \(error.localizedDescription)")
        }
    }
}

func extractPrice(from line: String) -> String? {
    let pricePattern = #"[-]?[\d]+[.,]\d{2}"#
    if let regex = try? NSRegularExpression(pattern: pricePattern, options: []) {
        let range = NSRange(location: 0, length: line.utf16.count)
        if let match = regex.firstMatch(in: line, options: [], range: range),
           let priceRange = Range(match.range, in: line) {
            return String(line[priceRange])
        }
    }
    return nil
}

func extractItemsAndPrices(from text: String) {
    let lines = text.components(separatedBy: "\n")
    var items: [(name: String, price: String)] = []

    var currentItemName = ""
    for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedLine.isEmpty { continue }

        if let price = extractPrice(from: trimmedLine) {
            var name = trimmedLine.replacingOccurrences(of: price, with: "").trimmingCharacters(in: .whitespaces)
            if name.isEmpty {
                name = currentItemName
            }
            if !name.isEmpty && !name.allSatisfy({ $0.isNumber || $0.isPunctuation }) {
                items.append((name: name, price: price))
                currentItemName = ""
            }
        } else {
            if !trimmedLine.allSatisfy({ $0.isSymbol || $0.isPunctuation }) {
                currentItemName = trimmedLine
            }
        }
    }

    // Imprimir los artículos y precios
    for item in items {
        print("Artículo: \(item.name), Precio: \(item.price)")
    }
}
