import Foundation

public struct TerminalSize: Equatable {
    public let cols: Int
    public let rows: Int
    public static let zero = TerminalSize(cols: 0, rows: 0)
}
