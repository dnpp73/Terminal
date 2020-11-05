import Foundation

public enum TerminalScrollEvent {
    case home
    case end
    case pageUp
    case pageDown
    case lineUp
    case lineDown

    internal var htermFunction: HtermScrollFunction {
        switch self {
        case .home: return .home
        case .end: return .end
        case .pageUp: return .pageUp
        case .pageDown: return .pageDown
        case .lineUp: return .lineUp
        case .lineDown: return .lineDown
        }
    }
}
