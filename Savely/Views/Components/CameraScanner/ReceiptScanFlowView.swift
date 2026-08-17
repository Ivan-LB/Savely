//
//  ReceiptScanFlowView.swift
//  Savely
//
//  The whole "Scan a receipt" flow in one presented view: capture (our
//  Warm Meadow camera, or Apple's document camera behind
//  FeatureFlags.useSystemDocumentCamera) → a visible "reading" state →
//  the review screen → saved. Presented full-screen from the "+" sheet and
//  from the Money tab; both hand it a ReceiptScanModel they own.
//

import SwiftUI
import VisionKit

struct ReceiptScanFlowView: View {
    @Bindable var model: ReceiptScanModel
    @Environment(\.dismiss) private var dismiss
    @AccessibilityFocusState private var focusedOverlay: ReceiptScanModel.Phase?

    private var usesSystemCamera: Bool {
        FeatureFlags.useSystemDocumentCamera && VNDocumentCameraViewController.isSupported
    }

    var body: some View {
        ZStack {
            captureLayer
                // The camera stays mounted under the overlays (so Retake is
                // instant), but its controls must not be reachable by
                // VoiceOver while another state is on top.
                .accessibilityHidden(model.phase != .capturing)
            overlay
        }
        .background(Color.black)
        .honorsReduceMotion()
        .animation(.easeInOut(duration: 0.2), value: model.phase)
        .onAppear { model.onFinished = { dismiss() } }
        .onChange(of: model.phase) { _, phase in
            announce(phase)
        }
        .statusBarHidden(model.phase == .capturing && !usesSystemCamera)
    }

    /// VoiceOver hears each state change and lands on the new screen.
    private func announce(_ phase: ReceiptScanModel.Phase) {
        let text: String?
        switch phase {
        case .capturing: text = nil
        case .processing: text = Strings.Camera.processingLabel
        case .review: text = Strings.Camera.reviewTitle
        case .failed: text = Strings.Camera.readFailedTitle
        }
        guard let text else { return }
        AccessibilityNotification.Announcement(text).post()
        focusedOverlay = phase
    }

    @ViewBuilder
    private var captureLayer: some View {
        if usesSystemCamera {
            if model.phase == .capturing {
                DocumentCameraView(
                    onScan: { image in model.importImage(image) },
                    onCancel: { model.cancel() },
                    onError: { model.importFailed() }
                )
                .ignoresSafeArea()
            } else {
                Color.warmBg.ignoresSafeArea()
            }
        } else {
            CameraView(model: model)
        }
    }

    @ViewBuilder
    private var overlay: some View {
        switch model.phase {
        case .capturing:
            EmptyView()
        case .processing:
            processing
        case .failed(let message):
            failed(message)
        case .review:
            ReceiptReviewView(model: model)
                .transition(.opacity)
                .accessibilityAddTraits(.isModal)
                .accessibilityFocused($focusedOverlay, equals: .review)
        }
    }

    private var processing: some View {
        VStack(spacing: 14) {
            ProgressView()
                .tint(.white) // deliberate: over the dimmed camera feed
            Text(Strings.Camera.processingLabel)
                .warmFont(15, weight: .medium)
                .foregroundStyle(.white) // deliberate: over the dimmed camera feed
            Button(action: { model.cancel() }) {
                Text(Strings.Buttons.cancelButton)
                    .warmFont(13, weight: .semibold)
                    .foregroundStyle(.white) // deliberate: over the dimmed camera feed
                    .frame(minHeight: 44)
                    .padding(.horizontal, 12)
            }
        }
        .padding(28)
        .background(Color.black.opacity(0.65)) // deliberate: over the dimmed camera feed
        .cornerRadius(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.25).ignoresSafeArea()) // deliberate: dims the camera feed
        .accessibilityAddTraits(.isModal)
        .accessibilityFocused($focusedOverlay, equals: .processing)
    }

    private func failed(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.magnifyingglass")
                .warmFont(32)
                .foregroundStyle(Color.warmInkMuted)
            Text(Strings.Camera.readFailedTitle)
                .warmFont(20, weight: .regular, design: .serif)
                .foregroundStyle(Color.warmInk)
                .multilineTextAlignment(.center)
            Text(message)
                .warmFont(13)
                .foregroundStyle(Color.warmInkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 10) {
                Button(action: { model.retake() }) {
                    Text(Strings.Camera.retryLabel)
                        .warmFont(13, weight: .semibold)
                        .foregroundStyle(Color.warmOnGreen)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .frame(minHeight: 44)
                        .background(Color.warmGreenFill)
                        .clipShape(Capsule())
                }
                Button(action: { model.cancel() }) {
                    Text(Strings.Buttons.cancelButton)
                        .warmFont(13, weight: .semibold)
                        .foregroundStyle(Color.warmInkSoft)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .frame(minHeight: 44)
                        .overlay(Capsule().stroke(Color.warmLine, lineWidth: 1))
                }
            }
            .padding(.top, 6)
        }
        .padding(24)
        .frame(maxWidth: 320)
        .background(Color.warmSurface)
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.warmLine, lineWidth: 1))
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.35).ignoresSafeArea()) // deliberate: dims the camera feed
        .accessibilityAddTraits(.isModal)
        .accessibilityFocused($focusedOverlay, equals: .failed(message))
    }
}
