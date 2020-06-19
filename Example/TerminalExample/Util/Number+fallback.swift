import UIKit

extension CGFloat {
    init(_ string: String, fallback: FloatLiteralType = 0.0) {
        if let i = Int(string) {
            self.init(i)
        } else {
            self.init(fallback)
        }
    }
}

extension Double {
    init(_ string: String, fallback: FloatLiteralType = 0.0) {
        if let i = Int(string) {
            self.init(i)
        } else {
            self.init(fallback)
        }
    }
}

extension Int {
    init(_ string: String, fallback: IntegerLiteralType = 0) {
        if let i = Int(string) {
            self.init(i)
        } else {
            self.init(fallback)
        }
    }
}

extension UInt {
    init(_ string: String, fallback: IntegerLiteralType = 0) {
        if let i = UInt(string) {
            self.init(i)
        } else {
            self.init(fallback)
        }
    }
}
