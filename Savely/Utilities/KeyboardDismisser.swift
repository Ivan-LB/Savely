//
//  KeyboardDismisser.swift
//  Savely
//
//  Tap anywhere outside a text field to put the keyboard away. Installed
//  once on the key window rather than per screen so every form, sheet and
//  wizard step gets it — including ones added later.
//

import UIKit

enum KeyboardDismisser {
    private static var installed = false

    /// Call from the root view's onAppear. If the window is not up yet
    /// (first frame), retries shortly — it must never silently give up.
    static func install() {
        guard !installed else { return }
        let windows = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
        guard let window = windows.first(where: \.isKeyWindow) ?? windows.first else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { install() }
            return
        }
        let tap = UITapGestureRecognizer(target: Handler.shared, action: #selector(Handler.dismiss))
        // Let the tap reach whatever was tapped (buttons, rows, another
        // field) — we only piggyback on it to resign the keyboard.
        tap.cancelsTouchesInView = false
        tap.delegate = Handler.shared
        window.addGestureRecognizer(tap)
        installed = true
    }

    private final class Handler: NSObject, UIGestureRecognizerDelegate {
        static let shared = Handler()

        @objc func dismiss() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }

        /// Don't fire for taps *inside* an editable control — those should
        /// place the caret, not close the keyboard.
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            var view = touch.view
            while let current = view {
                if current is UITextField || current is UITextView { return false }
                view = current.superview
            }
            return true
        }

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool {
            true
        }
    }
}
