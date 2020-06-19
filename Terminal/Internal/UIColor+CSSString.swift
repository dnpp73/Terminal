import UIKit

extension UIColor {

    private func convert8bit(_ value: CGFloat) -> Int {
        lround(Double(value) * 255.0)
    }

    var cssString: String {
        var r: CGFloat = 0.0
        var g: CGFloat = 0.0
        var b: CGFloat = 0.0
        var a: CGFloat = 0.0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "rgba(%ld, %ld, %ld, %ld)", convert8bit(r), convert8bit(g), convert8bit(b), convert8bit(a))
    }
}
