//
//  CameraView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 21/10/24.
//

import SwiftUI
import Vision
import UIKit

struct CameraView: View {
    @StateObject private var cameraManager = CameraManager()
    @Environment(\.presentationMode) var presentationMode
    private let textRecognizer = TextRecognizer()


    // Estado para la vista de confirmación de total
    @State private var showConfirmation = false
    @State private var detectedTotal: String = ""
    @State private var alternativeTotals: [String] = []


    var body: some View {


        ZStack {
            CameraPreview(cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)


            VStack {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()


                HStack {
                    Spacer()
                    Button(action: {
                        cameraManager.capturePhoto()
                    }) {
                        Image(systemName: "camera.circle.fill")
                            .resizable()
                            .frame(width: 70, height: 70)
                            .foregroundColor(.white)
                    }
                    .padding(.bottom, 30)
                    Spacer()
                }
            }


            // Mostrar la vista de confirmación si se detecta un total
            if showConfirmation {
                TotalConfirmationView(
                    detectedTotal: detectedTotal,
                    alternativeTotals: alternativeTotals,
                    onConfirm: { total in
                        print("Total confirmado: \(total)")
                        showConfirmation = false
                    },
                    onRetake: {
                        print("Tomando otra foto")
                        showConfirmation = false
                    }
                )
                .frame(width: 300, height: 400)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(radius: 10)
            }
        }
        .onAppear {
            cameraManager.startSession()
        }
        .onDisappear {
            cameraManager.stopSession()
        }
        .onChange(of: cameraManager.photoData) { data in
            if let data = data, let image = UIImage(data: data) {
                textRecognizer.recognizeText(in: image) { recognizedText in
                    if let recognizedText = recognizedText {
                        print("Texto reconocido: \n\(recognizedText)")


                        if let totalAmount = extractTotalAmount(from: recognizedText) {
                            detectedTotal = totalAmount
                            alternativeTotals = getAlternativeTotals(from: recognizedText)
                            showConfirmation = true
                        } else {
                            print("No se encontró un total.")
                        }


                    } else {
                        print("No se reconoció ningún texto en la imagen.")
                    }
                }
            }
        }
    }


    // Función para extraer el total considerando los posibles casos
    func extractTotalAmount(from text: String) -> String? {
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


    // Función auxiliar para extraer todos los valores monetarios de una línea de texto
    func extractMonetaryValues(from text: String) -> [Double] {
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


    // Función para obtener alternativas de total
    func getAlternativeTotals(from text: String) -> [String] {
        let allAmounts = extractMonetaryValues(from: text)
        return Array(allAmounts.prefix(3)).map { String(format: "%.2f", $0) }
    }
}
