//
//  CameraPreview.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 23/10/24.
//

import SwiftUI
import AVFoundation

struct CameraPreview: UIViewRepresentable {
    let cameraManager: CameraManager

    func makeUIView(context: Context) -> PreviewHostView {
        let view = PreviewHostView()
        view.backgroundColor = .black
        cameraManager.setPreviewLayer(to: view)
        view.onLayout = { [weak view] in
            guard let view else { return }
            cameraManager.layoutPreviewLayer(in: view)
        }
        return view
    }

    func updateUIView(_ uiView: PreviewHostView, context: Context) {}

    /// A plain view that tells the preview layer when its bounds change —
    /// UIScreen.main.bounds at creation time is wrong for a sheet and for
    /// rotation.
    final class PreviewHostView: UIView {
        var onLayout: (() -> Void)?
        override func layoutSubviews() {
            super.layoutSubviews()
            onLayout?()
        }
    }
}
