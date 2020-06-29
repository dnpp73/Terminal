import UIKit
import Terminal

final class TerminalViewController: UIViewController, TerminalViewDelegate, KeyboardPickerDelegate {

    private static let initialFontSize = "9"
    private static let fontSizes: [String] = Array(1...50).map { String($0) }

    private static let initialCursorShape = TerminalCursorShape.beam.rawValue
    private static let cursorShapes: [String] = [
        TerminalCursorShape.block.rawValue,
        TerminalCursorShape.beam.rawValue,
        TerminalCursorShape.underline.rawValue,
    ]

    private static let initialCursorBlink = "true"
    private static let cursorBlinks: [String] = ["true", "false"]

    private let terminalInputAccessoryView = InputAccessoryView.createFromNib()

    @IBOutlet private var terminalView: TerminalView!

    @IBOutlet private var fontSizePicker: KeyboardPicker!
    @IBOutlet private var cursorShapePicker: KeyboardPicker!
    @IBOutlet private var cursorBlinkPicker: KeyboardPicker!

    @IBOutlet private var terminalModeChangeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        terminalInputAccessoryView?.terminalView = terminalView

        terminalView.delegate = self
        terminalView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -8.0).isActive = true // fail if write `@IBOutlet var didSet` scope

        fontSizePicker.dataSource = Self.fontSizes
        fontSizePicker.delegate = self
        fontSizePicker.selectedData = Self.initialFontSize

        cursorShapePicker.dataSource = Self.cursorShapes
        cursorShapePicker.delegate = self
        cursorShapePicker.selectedData = Self.initialCursorShape

        cursorBlinkPicker.dataSource = Self.cursorBlinks
        cursorBlinkPicker.delegate = self
        cursorBlinkPicker.selectedData = Self.initialCursorBlink

        terminalViewDidChangeMode(terminalView)
    }

    @IBAction private func handleTouchUpInsideClearScrollbackButton(_ sender: UIButton) {
        terminalView?.terminalClear(.clearScrollback)
    }

    @IBAction private func handleTouchUpInsideResetButton(_ sender: UIButton) {
        terminalView?.terminalClear(.reset)
    }

    @IBAction private func handleTouchUpInsideSoftResetButton(_ sender: UIButton) {
        terminalView?.terminalClear(.softReset)
    }

    @IBAction private func handleTouchUpInsideReload(_ sender: UIButton) {
        terminalView?.reloadTerminal()
    }

    @IBAction private func handleTouchUpInsideScrollHome(_ sender: UIButton) {
        terminalView?.terminalScroll(.home)
    }

    @IBAction private func handleTouchUpInsideScrollEnd(_ sender: UIButton) {
        terminalView?.terminalScroll(.end)
    }

    @IBAction private func handleTouchUpInsideScrollPageUp(_ sender: UIButton) {
        terminalView?.terminalScroll(.pageUp)
    }

    @IBAction private func handleTouchUpInsideScrollPageDown(_ sender: UIButton) {
        terminalView?.terminalScroll(.pageDown)
    }

    @IBAction private func handleTouchUpInsideScrollLineUp(_ sender: UIButton) {
        terminalView?.terminalScroll(.lineUp)
    }

    @IBAction private func handleTouchUpInsideScrollLineDown(_ sender: UIButton) {
        terminalView?.terminalScroll(.lineDown)
    }

    @IBAction private func handleTouchUpInsideModeButton(_ sender: UIButton) {
        guard let t = terminalView else {
            return
        }
        switch t.mode {
        case .input: t.enterScrollMode()
        case .scroll: t.enterInputMode()
        }
    }

    @IBAction private func handleTouchUpInsideEditableChangeButton(_ sender: UIButton) {
        guard let t = terminalView else {
            return
        }
        t.isTerminalContentEditable.toggle()
        sender.setTitle("Editable: \(t.isTerminalContentEditable)", for: .normal)
    }

    @IBAction private func handleTouchUpInsideGetVisibleTextButton(_ sender: UIButton) {
        terminalView?.getVisibleText {
            print($0)
        }
    }

    @IBAction private func handleTouchUpInsideGetAllTextButton(_ sender: UIButton) {
        terminalView?.getAllText {
            print($0)
        }
    }

    func terminalViewDidLoad(_ terminalView: TerminalView) {
        print("[TerminalViewController(TerminalViewDelegate).terminalViewDidLoad:]")
    }

    func terminalView(_ terminalView: TerminalView, didChangeTerminalSize oldSize: TerminalSize) {
        print("[TerminalViewController(TerminalViewDelegate).terminalView:didChangeTerminalSize:] oldSize: \(oldSize), currentSize: \(terminalView.terminalSize)")
    }

    func terminalView(_ terminalView: TerminalView, didHandleURL url: URL) {
        print("[TerminalViewController(TerminalViewDelegate).terminalView:didHandleURL:] url: \(url)")
    }

    func terminalView(_ terminalView: TerminalView, didHandleKeyInput string: String) {
        print("[TerminalViewController(TerminalViewDelegate).terminalView:didHandleKeyInput:] string: \(string)")
        if let data = string.data(using: .utf8) {
            terminalView.appendBuffer(data)
        }
    }

    func terminalView(_ terminalView: TerminalView, didHandleSendString string: String) {
        print("[TerminalViewController(TerminalViewDelegate).terminalView:didHandleSendString:] string: \(string)")
        if let data = string.data(using: .utf8) {
            terminalView.appendBuffer(data)
        }
    }

    func terminalViewDidHandleDeleteBackward(_ terminalView: TerminalView) {
        print("[TerminalViewController(TerminalViewDelegate).terminalViewDidHandleDeleteBackward:]")
        // terminalView.terminalErase(.toLeft)
        // terminalView.terminalClear(.clear)
        terminalView.press(.backspace)
    }

    func terminalView(_ terminalView: TerminalView, didHandleOnVTKeyStroke string: String) {
        print("[TerminalViewController(TerminalViewDelegate).terminalView:didHandleOnVTKeyStroke:] \(string)")
        if let data = string.data(using: .utf8) {
            terminalView.appendBuffer(data)
        }
    }

    func terminalViewRequestInputAccessoryView(_ terminalView: TerminalView) -> UIView? {
        print("[TerminalViewController(TerminalViewDelegate).terminalView:terminalViewRequestInputAccessoryView:]")
        return terminalInputAccessoryView
    }

    func terminalViewRequestInputAccessoryViewController(_ terminalView: TerminalView) -> UIInputViewController? {
        print("[TerminalViewController(TerminalViewDelegate).terminalView:terminalViewRequestInputAccessoryViewController:]")
        return nil
    }

    func terminalViewDidChangeMode(_ terminalView: TerminalView) {
        let title: String
        switch terminalView.mode {
        case .input: title = "Mode: input"
        case .scroll: title = "Mode: scroll"
        }
        terminalModeChangeButton.setTitle(title, for: .normal)
    }

    func keyboardPicker(_ keyboardPicker: KeyboardPicker, didSelect index: Int) {
        guard let terminalView = terminalView else {
            return
        }
        switch keyboardPicker {
        case fontSizePicker:
            let fontSize = UInt(keyboardPicker.selectedData, fallback: 9)
            terminalView.terminalFontSize = fontSize
        case cursorShapePicker:
            if let shape = TerminalCursorShape(rawValue: keyboardPicker.selectedData) {
                terminalView.terminalCursorShape = shape
            }
        case cursorBlinkPicker:
            let isBlink = keyboardPicker.selectedData == "true"
            terminalView.isTerminalCursorBlink = isBlink
        default:
            break
        }
    }

}
