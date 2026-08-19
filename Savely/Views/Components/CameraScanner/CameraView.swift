//
//  CameraView.swift
//  Savely
//
//  Created by Ivan Lorenzana Belli on 21/10/24.
//
//  The custom Warm Meadow capture surface: live preview, a guide frame,
//  torch, gallery import and the shutter. State lives in ReceiptScanModel;
//  processing/failure/review overlays are drawn by ReceiptScanFlowView on
//  top of this view.
//

import SwiftUI
import PhotosUI

struct CameraView: View {
    @Bindable var model: ReceiptScanModel
    @State private var pickedItem: PhotosPickerItem?
    @Environment(\.scenePhase) private var scenePhase

    /// Scrim behind white text/glyphs drawn over the live feed — the feed is
    /// usually a white receipt on a table, so 35 % black is not enough for
    /// legible white text; this keeps the contrast ≥ 4.5:1 on any subject.
    private let overlayScrim = Color.black.opacity(0.6) // deliberate: over the camera feed

    private var camera: CameraManager { model.camera }

    var body: some View {
        ZStack {
            CameraPreview(cameraManager: camera)
                .ignoresSafeArea()

            // Guide frame: where the receipt should sit. Decorative only.
            GuideFrame()
                .padding(.horizontal, 28)
                .padding(.top, 84)
                .padding(.bottom, 190)
                .accessibilityHidden(true)

            if !camera.isCameraAvailable {
                unavailableCard
            }

            VStack(spacing: 0) {
                topBar
                Spacer()
                bottomBar
            }
        }
        .onAppear { camera.startSession() }
        .onDisappear { camera.stopSession() }
        .onChange(of: scenePhase) { _, phase in
            // Back from Settings after granting camera access: try again.
            if phase == .active, !camera.isCameraAvailable { camera.startSession() }
        }
        .onChange(of: pickedItem) { _, item in
            guard let item else { return }
            model.beginImport()
            Task {
                defer { pickedItem = nil }
                do {
                    if let data = try await item.loadTransferable(type: Data.self), let image = UIImage(data: data) {
                        model.importImage(image)
                        return
                    }
                    print("Photo import: no decodable image data")
                } catch {
                    print("Photo import failed: \(error)")
                }
                model.importFailed()
            }
        }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack {
            Button(action: { model.cancel() }) {
                Image(systemName: "xmark")
                    .warmFont(15, weight: .semibold)
                    .foregroundStyle(.white) // deliberate: drawn over the live camera feed
                    .frame(width: 40, height: 40)
                    .background(overlayScrim)
                    .clipShape(Circle())
                    .tappable44()
            }
            .accessibilityLabel(Strings.Camera.closeLabel)
            Spacer()
            if camera.hasTorch {
                Button(action: { camera.toggleTorch() }) {
                    Image(systemName: camera.isTorchOn ? "bolt.fill" : "bolt.slash")
                        .warmFont(15, weight: .semibold)
                        .foregroundStyle(.white) // deliberate: over the camera feed
                        .frame(width: 40, height: 40)
                        .background(overlayScrim)
                        .clipShape(Circle())
                        .tappable44()
                }
                .accessibilityLabel(camera.isTorchOn ? Strings.Camera.torchOffLabel : Strings.Camera.torchOnLabel)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            Text(Strings.Camera.guideHint)
                .warmFont(13, weight: .medium)
                .foregroundStyle(.white) // deliberate: over the camera feed
                .multilineTextAlignment(.center)
                .padding(.horizontal, 14).padding(.vertical, 8)
                .background(overlayScrim)
                .clipShape(Capsule())
                .padding(.horizontal, 32)

            HStack(alignment: .center) {
                PhotosPicker(selection: $pickedItem, matching: .images, photoLibrary: .shared()) {
                    Image(systemName: "photo.on.rectangle")
                        .warmFont(20)
                        .foregroundStyle(.white) // deliberate: over the camera feed
                        .frame(width: 52, height: 52)
                        .background(overlayScrim)
                        .clipShape(Circle())
                }
                .accessibilityLabel(Strings.Camera.importFromPhotosLabel)
                .frame(maxWidth: .infinity)

                Button(action: { model.capture() }) {
                    ZStack {
                        Circle().stroke(Color.white, lineWidth: 4).frame(width: 76, height: 76) // deliberate: shutter over the camera feed
                        Circle().fill(Color.white).frame(width: 62, height: 62) // deliberate: shutter over the camera feed
                    }
                }
                .disabled(!camera.isCameraAvailable || !camera.isRunning || model.isProcessing)
                .opacity(camera.isCameraAvailable && camera.isRunning ? 1 : 0.35)
                .accessibilityLabel(Strings.Camera.shutterLabel)
                .frame(maxWidth: .infinity)

                Color.clear.frame(width: 52, height: 52).frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)

            Text(Strings.Camera.privacyNote)
                .warmFont(11)
                .foregroundStyle(.white) // deliberate: over the camera feed
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(overlayScrim)
                .clipShape(Capsule())
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 24)
    }

    /// No live feed behind this card, so it uses the Warm Meadow tokens.
    private var unavailableCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "camera.badge.ellipsis")
                .warmFont(36)
                .foregroundStyle(Color.warmInkMuted)
                .accessibilityHidden(true)
            Text(Strings.Camera.cameraUnavailableTitle)
                .warmFont(17, weight: .semibold)
                .foregroundStyle(Color.warmInk)
            Text(Strings.Camera.cameraUnavailableBody)
                .warmFont(13)
                .foregroundStyle(Color.warmInkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            if let url = URL(string: UIApplication.openSettingsURLString) {
                Link(Strings.Camera.openSettingsLabel, destination: url)
                    .warmFont(13, weight: .semibold)
                    .foregroundStyle(Color.warmOnGreen)
                    .padding(.horizontal, 16).padding(.vertical, 10)
                    .frame(minHeight: 44)
                    .background(Color.warmGreenFill)
                    .clipShape(Capsule())
                    .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: 300)
        .background(Color.warmSurface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.warmLine, lineWidth: 1))
        .accessibilityElement(children: .contain)
    }
}

/// A rounded rectangle with corner ticks — the "put the receipt here" hint.
private struct GuideFrame: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 18)
            .strokeBorder(Color.white.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])) // deliberate: over the camera feed
            .allowsHitTesting(false)
    }
}
