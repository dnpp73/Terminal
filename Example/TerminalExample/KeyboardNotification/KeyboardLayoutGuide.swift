//
//  KeyboardLayoutGuide.swift
//  KeyboardLayoutGuide
//
//  Created by Sacha DSO on 14/11/2017.
//  Copyright © 2017 freshos. All rights reserved.
//
//  https://github.com/freshOS/KeyboardLayoutGuide/blob/8f2f7b600fcb788fdda571b19b86a560ef2f9559/Sources/KeyboardLayoutGuide/KeyboardLayoutGuide.swift

import UIKit

private class Keyboard {
    fileprivate static let shared = Keyboard()
    private init() {}
    fileprivate var currentHeight: CGFloat = 0
}

extension UIView {
    private enum Identifiers {
        static var usingSafeArea = "KeyboardLayoutGuideUsingSafeArea"
        static var notUsingSafeArea = "KeyboardLayoutGuide"
    }

    /// A layout guide representing the inset for the keyboard.
    /// Use this layout guide’s top anchor to create constraints pinning to the top of the keyboard or the bottom of safe area.
    var keyboardLayoutGuide: UILayoutGuide {
        getOrCreateKeyboardLayoutGuide(identifier: Identifiers.usingSafeArea, usesSafeArea: true)
    }

    /// A layout guide representing the inset for the keyboard.
    /// Use this layout guide’s top anchor to create constraints pinning to the top of the keyboard or the bottom of the view.
    var keyboardLayoutGuideNoSafeArea: UILayoutGuide {
        getOrCreateKeyboardLayoutGuide(identifier: Identifiers.notUsingSafeArea, usesSafeArea: false)
    }

    private func getOrCreateKeyboardLayoutGuide(identifier: String, usesSafeArea: Bool) -> UILayoutGuide {
        if let existing = layoutGuides.first(where: { $0.identifier == identifier }) {
            return existing
        }
        let new = KeyboardLayoutGuide()
        new.usesSafeArea = usesSafeArea
        new.identifier = identifier
        addLayoutGuide(new)
        new.setUp()
        return new
    }
}

class KeyboardLayoutGuide: UILayoutGuide {
    var usesSafeArea = true {
        didSet {
            updateButtomAnchor()
        }
    }

    private var bottomConstraint: NSLayoutConstraint?

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(notificationCenter: NotificationCenter = NotificationCenter.default) {
        super.init()
        // Observe keyboardWillChangeFrame notifications
        notificationCenter.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    fileprivate func setUp() {
        guard let view = owningView else {
            return
        }
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: Keyboard.shared.currentHeight),
            leftAnchor.constraint(equalTo: view.leftAnchor),
            rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        updateButtomAnchor()
    }

    func updateButtomAnchor() {
        if let bottomConstraint = bottomConstraint {
            bottomConstraint.isActive = false
        }

        guard let view = owningView else {
            return
        }

        let viewBottomAnchor: NSLayoutYAxisAnchor
        if #available(iOS 11.0, *), usesSafeArea {
            viewBottomAnchor = view.safeAreaLayoutGuide.bottomAnchor
        } else {
            viewBottomAnchor = view.bottomAnchor
        }

        bottomConstraint = bottomAnchor.constraint(equalTo: viewBottomAnchor)
        bottomConstraint?.isActive = true
    }

    @objc
    private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let keyboardInfo = notification.keyboardInfo else {
            return
        }
        let frameEnd = keyboardInfo.frameEnd
        let screenHeight = UIApplication.shared.keyWindow?.bounds.height ?? UIScreen.main.bounds.height
        var height = screenHeight - frameEnd.minY
        let duration = keyboardInfo.animationDuration
        if #available(iOS 11.0, *), usesSafeArea, height > 0, let bottom = owningView?.safeAreaInsets.bottom {
            height -= bottom
        }
        heightConstraint?.constant = height
        if duration > 0.0 {
            animate(notification)
        }
        Keyboard.shared.currentHeight = height
    }

    private func animate(_ notification: Notification) {
        if let owningView = self.owningView, isVisible(view: owningView) {
            self.owningView?.layoutIfNeeded()
        } else {
            UIView.performWithoutAnimation {
                self.owningView?.layoutIfNeeded()
            }
        }
    }
}

// MARK: - Helpers

extension UILayoutGuide {
    fileprivate var heightConstraint: NSLayoutConstraint? {
        owningView?.constraints.first {
            $0.firstItem as? UILayoutGuide == self && $0.firstAttribute == .height
        }
    }
}

/// Credits to John Gibb for this nice helper :)
/// https://stackoverflow.com/questions/1536923/determine-if-uiview-is-visible-to-the-user
private func isVisible(view: UIView) -> Bool {
    func isVisible(view: UIView, inView: UIView?) -> Bool {
        guard let inView = inView else {
            return true
        }
        let viewFrame = inView.convert(view.bounds, from: view)
        if viewFrame.intersects(inView.bounds) {
            return isVisible(view: view, inView: inView.superview)
        }
        return false
    }
    return isVisible(view: view, inView: view.superview)
}
