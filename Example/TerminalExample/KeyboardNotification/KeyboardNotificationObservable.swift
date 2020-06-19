import UIKit

protocol KeyboardNotificationObservable: AnyObject {
    var keyboardNotificationTokens: [Any] { get set }
    func addObserverKeyboardNotifications()
    func removeObserverKeyboardNotifications()
    func handleKeyboardNotification(_ notification: Notification)
}

let keyboardNotificationKeys: [Notification.Name] = [
    UIResponder.keyboardWillShowNotification,
    UIResponder.keyboardDidShowNotification,
    UIResponder.keyboardWillHideNotification,
    UIResponder.keyboardDidHideNotification,
    UIResponder.keyboardWillChangeFrameNotification,
    UIResponder.keyboardDidChangeFrameNotification
]

extension KeyboardNotificationObservable {

    func addObserverKeyboardNotifications() {
        if keyboardNotificationTokens.count > 0 {
            return
        }
        keyboardNotificationTokens = keyboardNotificationKeys.compactMap { (name: Notification.Name) -> Any in
            let token = NotificationCenter.default.addObserver(forName: name, object: nil, queue: nil) { [weak self] (notification: Notification) in
                self?.handleKeyboardNotification(notification)
            }
            return token // for swiftlint hack. for discarded_notification_center_observer rule
        }
    }

    func removeObserverKeyboardNotifications() {
        if keyboardNotificationTokens.count == 0 {
            return
        }
        keyboardNotificationTokens.forEach {
            NotificationCenter.default.removeObserver($0)
        }
    }

}
