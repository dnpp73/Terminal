import UIKit

extension Notification {
    var keyboardInfo: KeyboardInfo? {
        guard keyboardNotificationKeys.contains(name) else {
            return nil
        }
        return KeyboardInfo(userInfo: userInfo)
    }

    struct KeyboardInfo {

        let userInfo: [AnyHashable: Any]?

        var frameBegin: CGRect {
            guard let rect = userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect else {
                fatalError("missing keyboardFrameBegin value in userInfo")
            }
            return rect
        }

        var frameEnd: CGRect {
            guard let rect = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                fatalError("missing keyboardFrameEnd value in userInfo")
            }
            return rect
        }

        var animationDuration: TimeInterval {
            guard let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else {
                fatalError("missing keyboardAnimationDuration in userInfo")
            }
            return duration
        }

        var animationCurve: UIView.AnimationCurve {
            guard let rawValue = userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? Int else {
                fatalError("missing keyboardAnimationCurve in userInfo")
            }
            guard let animationCurve = UIView.AnimationCurve(rawValue: rawValue) else {
                fatalError("invalid rawValue for UIView.AnimationCurve. rawValue: \(rawValue)")
            }
            return animationCurve
        }

        var isLocal: Bool {
            guard let keyboardIsLocal = userInfo?[UIResponder.keyboardIsLocalUserInfoKey] as? Bool else {
                fatalError("missing keyboardIsLocal in userInfo")
            }
            return keyboardIsLocal
        }

    }
}
