//
//  RectangleOverlay.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 23/10/24.
//

import SwiftUI
import Vision

struct RectangleOverlay: Shape {
    var rectangle: VNRectangleObservation

    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Convertir las coordenadas normalizadas a coordenadas de vista
        let topLeft = CGPoint(x: rectangle.topLeft.x * rect.width, y: (1 - rectangle.topLeft.y) * rect.height)
        let topRight = CGPoint(x: rectangle.topRight.x * rect.width, y: (1 - rectangle.topRight.y) * rect.height)
        let bottomRight = CGPoint(x: rectangle.bottomRight.x * rect.width, y: (1 - rectangle.bottomRight.y) * rect.height)
        let bottomLeft = CGPoint(x: rectangle.bottomLeft.x * rect.width, y: (1 - rectangle.bottomLeft.y) * rect.height)

        path.move(to: topLeft)
        path.addLine(to: topRight)
        path.addLine(to: bottomRight)
        path.addLine(to: bottomLeft)
        path.closeSubpath()

        return path
    }
}
