//
//  CameraViewModel.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 19/11/24.
//

import Foundation
import SwiftUI
import Vision
import Combine

class CameraViewModel: ObservableObject {
    @Published var showConfirmation = false
    @Published var detectedTotal: String = ""
    @Published var alternativeTotals: [String] = []
    @Published var isRectangleDetected: Bool = false
    @Published var detectedRectangle: VNRectangleObservation?

    private let textRecognizer = TextRecognizer()
    private var cancellables = Set<AnyCancellable>()
    @ObservedObject var cameraManager = CameraManager()
    var expenseViewModel: ExpenseTrackerViewModel

    // Necesitamos una referencia a presentationMode
    var dismissCameraView: (() -> Void)?

    init(expenseViewModel: ExpenseTrackerViewModel) {
        self.expenseViewModel = expenseViewModel
        bindCameraManager()
    }

    private func bindCameraManager() {
        // Observar photoData para procesar la imagen capturada
        cameraManager.$photoData
            .compactMap { $0 }
            .sink { [weak self] data in
                self?.processCapturedPhoto(data)
            }
            .store(in: &cancellables)

        // Observar isRectangleDetected y detectedRectangle
        cameraManager.$isRectangleDetected
            .receive(on: RunLoop.main)
            .assign(to: \.isRectangleDetected, on: self)
            .store(in: &cancellables)

        cameraManager.$detectedRectangle
            .receive(on: RunLoop.main)
            .assign(to: \.detectedRectangle, on: self)
            .store(in: &cancellables)
    }

    func startSession() {
        cameraManager.startSession()
    }

    func stopSession() {
        cameraManager.stopSession()
    }

    func capturePhoto() {
        cameraManager.capturePhoto()
    }

    private func processCapturedPhoto(_ data: Data) {
        if let image = UIImage(data: data) {
            textRecognizer.recognizeText(in: image) { [weak self] recognizedText in
                guard let self = self else { return }
                if let recognizedText = recognizedText {
                    // print("Texto reconocido: \n\(recognizedText)")

                    if let totalAmount = self.extractTotalAmount(from: recognizedText) {
                        DispatchQueue.main.async {
                            self.detectedTotal = totalAmount
                            self.alternativeTotals = self.getAlternativeTotals(from: recognizedText)
                            self.showConfirmation = true
                        }
                    } else {
                        print("No se encontró un total.")
                    }
                } else {
                    print("No se reconoció ningún texto en la imagen.")
                }
            }
        }
    }

    // Funciones para extraer el total y valores monetarios
    private func extractTotalAmount(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines)
        var amountsWithIndices: [(amount: Double, index: Int)] = []


        // Buscar los índices de las líneas que contienen variantes de "Total"
        let totalIndices = lines.enumerated().compactMap { (index, line) -> Int? in
            let lowercasedLine = line.lowercased()
            if lowercasedLine.contains("total") || lowercasedLine.contains("total:") {
                return index
            }
            return nil
        }


        // Extraer todos los valores monetarios válidos y sus índices
        for (index, line) in lines.enumerated() {
            let potentialAmounts = extractMonetaryValues(from: line)
            for amount in potentialAmounts {
                let lowercasedLine = line.lowercased()
                if amount >= 10 && amount <= 1000000,
                   !lowercasedLine.contains("cash") &&
                   !lowercasedLine.contains("change") &&
                   !lowercasedLine.contains("tend") &&
                   !lowercasedLine.contains("debit") {
                    amountsWithIndices.append((amount: amount, index: index))
                }
            }
        }


        // Filtrar los valores que estén cerca de cualquiera de las líneas con "Total"
        var nearbyAmounts: [Double] = []
        for totalIndex in totalIndices {
            let nearby = amountsWithIndices.filter { abs($0.index - totalIndex) <= 3 }
            nearbyAmounts.append(contentsOf: nearby.map { $0.amount })
        }


        // Si hay valores válidos cercanos a "Total", seleccionar el mayor de ellos
        if let probableTotal = nearbyAmounts.max() {
            return String(format: "%.2f", probableTotal)
        }

        // Si no se encuentran valores cercanos a "Total", usar el valor máximo general como respaldo
        return amountsWithIndices.map { $0.amount }.max().map { String(format: "%.2f", $0) }
    }

    private func extractMonetaryValues(from text: String) -> [Double] {
        var values: [Double] = []
        let regex = try? NSRegularExpression(pattern: "\\d{1,3}(?:[.,]\\d{3})*(?:[.,]\\d{2})", options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        
        regex?.enumerateMatches(in: text, options: [], range: range) { match, _, _ in
            if let match = match {
                var valueString = (text as NSString).substring(with: match.range)
                valueString = valueString.replacingOccurrences(of: ",", with: "")
                valueString = valueString.replacingOccurrences(of: ".", with: ".")
                if let value = Double(valueString) {
                    values.append(value)
                }
            }
        }
        
        return values
    }

    private func getAlternativeTotals(from text: String) -> [String] {
        let allAmounts = extractMonetaryValues(from: text)
        return Array(allAmounts.prefix(3)).map { String(format: "%.2f", $0) }
    }

    // Funciones para manejar la confirmación del total
    func confirmTotal(_ total: String) {
        expenseViewModel.expenseDescription = "Recibo escaneado"
        expenseViewModel.amount = total
        expenseViewModel.addExpense()
        showConfirmation = false
        dismissCameraView?()
    }

    func retakePhoto() {
        showConfirmation = false
    }
}
