import Foundation

public enum TerminalKeyDownEvent {
    case escape
    case backspace
    case tab
    case pageUp
    case pageDown
    case leftArrow
    case upArrow
    case downArrow
    case rightArrow

    internal var string: String {
        switch self {
        case .escape: return .terminalEscape
        case .backspace: return .terminalBackspace
        case .tab: return .terminalTab
        case .pageUp: return .terminalPageUp
        case .pageDown: return .terminalPageDown
        case .leftArrow: return .terminalLeftArrow
        case .upArrow: return .terminalUpArrow
        case .downArrow: return .terminalDownArrow
        case .rightArrow: return .terminalRightArrow
        }
    }
}
