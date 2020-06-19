import Foundation

extension String {
    static let terminalEscape: Self = "\u{1b}"
    static let terminalBackspace: Self = "\u{7f}"

    static let terminalTab: Self = "\t"
    static let terminalBackTab: Self = .terminalEscape + "[Z" // ^[[Z https://stuff.mit.edu/afs/sipb/user/daveg/Info/backtab-howto.txt

    static let terminalPageUp: Self = .terminalEscape + "[5~" // https://github.com/mintty/mintty/wiki/Keycodes#editing-keys
    static let terminalPageDown: Self = .terminalEscape + "[6~" // https://github.com/mintty/mintty/wiki/Keycodes#editing-keys

    static let terminalLeftArrow: Self = terminalEscape + "[D"
    static let terminalUpArrow: Self = terminalEscape + "[A"
    static let terminalDownArrow: Self = terminalEscape + "[B"
    static let terminalRightArrow: Self = terminalEscape + "[C"
}
