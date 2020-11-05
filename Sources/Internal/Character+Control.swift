import Foundation

let controlKeys = "abcdefghijklmnopqrstuvwxyz@^-=[]\\".sorted()

extension Character {

    private static let controlMask: UInt8 = 0x40

    private var canCombineWithControl: Bool {
        controlKeys.contains(self)
    }

    func combineWithControlKey() -> Self? {
        guard canCombineWithControl else {
            return nil
        }
        guard let asciiCode = Character(uppercased()).asciiValue else {
            return nil
        }
        let masked = asciiCode ^ Self.controlMask
        return Self(UnicodeScalar(masked))
    }

}

extension String {
    func combineWithControlKey() -> Self? {
        guard count == 1 else {
            return nil
        }
        guard let controlled = Character(self).combineWithControlKey() else {
            return nil
        }
        return String(controlled)
    }
}
