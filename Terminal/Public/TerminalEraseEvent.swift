import Foundation

public enum TerminalEraseEvent {
    case toLeft
    case toRight
    case line
    case above
    case below

    internal var htermFunction: HtermEraseFunction {
        switch self {
        case .toLeft: return .toLeft
        case .toRight: return .toRight
        case .line: return .line
        case .above: return .above
        case .below: return .below
        }
    }
}
