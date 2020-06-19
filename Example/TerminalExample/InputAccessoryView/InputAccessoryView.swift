import UIKit
import Terminal

final class InputAccessoryView: UIView, NibCreatable {

    weak var terminalView: TerminalView?

    @IBAction private func handleTouchUpInsideTerminalInputAccessoryEscapeButton(_ sender: UIButton) {
        terminalView?.press(.escape)
    }

    @IBAction private func handleTouchUpInsideTerminalInputAccessoryTabButton(_ sender: UIButton) {
        terminalView?.press(.tab)
    }

    @IBAction private func handleTouchUpInsideTerminalInputAccessoryControlButton(_ sender: UIButton) {
        guard let terminalView = terminalView else {
            return
        }
        terminalView.isControlKeyPressed.toggle()
        sender.isSelected = terminalView.isControlKeyPressed
    }

    @IBAction private func handleTouchUpInsideTerminalInputAccessoryMetaButton(_ sender: UIButton) {
        guard let terminalView = terminalView else {
            return
        }
        terminalView.isMetaKeyPressed.toggle()
        sender.isSelected = terminalView.isMetaKeyPressed
    }

    @IBAction private func handleTouchUpInsideTerminalInputAccessoryLeftArrowButton(_ sender: UIButton) {
        terminalView?.press(.leftArrow)
    }

    @IBAction private func handleTouchUpInsideTerminalInputAccessoryDownArrowButton(_ sender: UIButton) {
        terminalView?.press(.downArrow)
    }

    @IBAction private func handleTouchUpInsideTerminalInputAccessoryUpArrowButton(_ sender: UIButton) {
        terminalView?.press(.upArrow)
    }

    @IBAction private func handleTouchUpInsideTerminalInputAccessoryRightArrowButton(_ sender: UIButton) {
        terminalView?.press(.rightArrow)
    }

    @IBAction private func handleTouchUpInsideTerminalInputAccessoryCloseButton(_ sender: UIButton) {
        _ = terminalView?.resignFirstResponder()
    }

}
