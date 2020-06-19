import Foundation

let metaKeys = "abcdefghijklmnopqrstuvwxyz0123456789-=[]\\;',./".sorted()

extension Character {
    fileprivate var canCombineWithMeta: Bool {
        metaKeys.contains(self)
    }
}

extension String {
    func combineWithMetaKey() -> Self? {
        guard count == 1 else {
            return nil
        }
        guard Character(self).canCombineWithMeta else {
            return nil
        }
        return Self.terminalEscape + self
    }
}
