import Foundation

public enum TerminalClearEvent {
    case clearScrollback
    case reset
    case softReset
    case clearHome
    case clear

    internal var htermFunction: HtermClearFunction {
        switch self {
        case .clearScrollback: return .clearScrollback
        case .reset: return .reset
        case .softReset: return .softReset
        case .clearHome: return .clearHome
        case .clear: return .clear
        }
    }
}
