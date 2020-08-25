import UIKit
import NMSSH
import Terminal

func debugLog(fileName: String = #file, line: Int = #line, functionName: String = #function, _ msg: String = "") {
    #if DEBUG
    print("\(Date().description) [\(fileName.split(separator: "/").last ?? "") @L\(line) \(functionName)] " + msg)
    #endif
}

final class SSHTerminalViewController: UIViewController {

    fileprivate let sshQueue = DispatchQueue(label: "NMSSH.queue.SSHTerminalViewController")
    fileprivate var session: NMSSHSession?
    fileprivate var channel: NMSSHChannel? { session?.channel }

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

    @IBOutlet private var userNameTextField: UITextField!
    @IBOutlet private var hostNameTextField: UITextField!
    @IBOutlet private var passwordTextField: UITextField!
    @IBOutlet private var actionBarButtonItem: UIBarButtonItem!

    @IBOutlet fileprivate var terminalView: TerminalView!

    @IBOutlet fileprivate var fontSizePicker: KeyboardPicker!
    @IBOutlet fileprivate var cursorShapePicker: KeyboardPicker!
    @IBOutlet fileprivate var cursorBlinkPicker: KeyboardPicker!

    @IBOutlet private var terminalModeChangeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        hostNameTextField?.text = UserDefaults.standard.string(forKey: kSSHHostNameDefaultsKey)

        terminalInputAccessoryView?.terminalView = terminalView

        terminalView.delegate = self
        terminalView.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor).isActive = true // fail if write `@IBOutlet var didSet` scope

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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disconnect()
    }

    fileprivate func changeBarButtonItemTitleOnMainThread(_ title: String) {
        let execute: () -> Void = { [weak self] in
            guard let actionBarButtonItem = self?.actionBarButtonItem else {
                return
            }
            actionBarButtonItem.title = title
        }
        if Thread.isMainThread {
            execute()
        } else {
            DispatchQueue.main.async(execute: execute)
        }
    }

    // MARK: - IBActions

    @IBAction private func handleActionBarButtonItem(_ sender: UIBarButtonItem) {
        if session?.isConnected ?? false {
            disconnect()
        } else {
            connect()
        }
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
        actionBarButtonItem?.isEnabled = false
        disconnect()
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

    // MARK: - SSH Connection

    private func connect() {
        guard let user = userNameTextField?.text, let host = hostNameTextField?.text, let pass = passwordTextField?.text else {
            return
        }

        UserDefaults.standard.set(host, forKey: kSSHHostNameDefaultsKey)
        UserDefaults.standard.synchronize()

        let s = terminalView.terminalSize
        let w = UInt(s.cols)
        let h = UInt(s.rows)

        sshQueue.async {
            let session = NMSSHSession.connect(toHost: host, withUsername: user)
            self.session = session
            session.delegate = self
            if session.isConnected == false {
                debugLog("[ERROR] connection failed.")
                return
            }
            debugLog("[INFO] connected: " + session.username + "@" + host)

            session.authenticate(byPassword: pass)
            if session.isAuthorized == false {
                debugLog("[ERROR] authentication failed.")
                return
            }
            debugLog("[INFO] authenticate success.")

            session.channel.ptyTerminalType = .xterm
            session.channel.requestPty = true
            session.channel.delegate = self
            // requestSizeWidth() is not here. should be after startShell()

            do {
                try session.channel.startShell()

                let success = session.channel.requestSizeWidth(w, height: h)
                debugLog("[INFO] requestSizeWidth success: \(success)")

                self.changeBarButtonItemTitleOnMainThread("Disconnect")
            } catch let e {
                let message = "[ERROR] " + e.localizedDescription
                debugLog(message)
            }
        }
    }

    private func disconnect() {
        sshQueue.async {
            if let session = self.session {
                session.disconnect()
            }
            self.session = nil // need clear. should not reuse.
        }
        changeBarButtonItemTitleOnMainThread("Connect")
    }

    fileprivate func writeSSHChannel(_ string: String) {
        sshQueue.async {
            guard let channel = self.channel else {
                return
            }
            var error: NSError?
            channel.write(string, error: &error, timeout: NSNumber(value: 10))
        }
    }

    fileprivate func writeSSHChannel(_ data: Data) {
        sshQueue.async {
            guard let channel = self.channel else {
                return
            }
            var error: NSError?
            channel.write(data, error: &error, timeout: NSNumber(value: 10))
        }
    }

}

extension SSHTerminalViewController: NMSSHSessionDelegate {

    func session(_ session: NMSSHSession, shouldConnectToHostWithFingerprint fingerprint: String) -> Bool {
        debugLog("[INFO] fingerprint: \(fingerprint)")
        return true
    }

    func session(_ session: NMSSHSession, didDisconnectWithError error: Error) {
        let message = "[ERROR] " + error.localizedDescription
        debugLog(message)
        changeBarButtonItemTitleOnMainThread("Connect")
    }

}

extension SSHTerminalViewController: NMSSHChannelDelegate {

    func channel(_ channel: NMSSHChannel, didReadRawData data: Data) {
        terminalView.appendBuffer(data)
    }

    func channel(_ channel: NMSSHChannel, didReadRawError error: Data) {
        terminalView.appendBuffer(error)
    }

    func channelShellDidClose(_ channel: NMSSHChannel) {
        debugLog("[INFO] Shell Closed.")
    }

}

extension SSHTerminalViewController: TerminalViewDelegate {

    func terminalViewDidLoad(_ terminalView: TerminalView) {
        actionBarButtonItem.isEnabled = true
    }

    func terminalView(_ terminalView: TerminalView, didChangeTerminalSize oldSize: TerminalSize) {
        guard let channel = channel else {
            return
        }
        let s = terminalView.terminalSize
        let w = UInt(s.cols)
        let h = UInt(s.rows)
        let success = channel.requestSizeWidth(w, height: h)
        debugLog("oldSize: \(oldSize), currentSize: \(terminalView.terminalSize), success: \(success)")
    }

    func terminalView(_ terminalView: TerminalView, didHandleURL url: URL) {
    }

    func terminalView(_ terminalView: TerminalView, didHandleKeyInput string: String) {
        writeSSHChannel(string)
    }

    func terminalViewDidHandleDeleteBackward(_ terminalView: TerminalView) {
        terminalView.press(.backspace)
    }

    func terminalView(_ terminalView: TerminalView, didHandleSendString string: String) {
        writeSSHChannel(string)
    }

    func terminalView(_ terminalView: TerminalView, didHandleOnVTKeyStroke string: String) {
        writeSSHChannel(string)
    }

    func terminalViewRequestInputAccessoryView(_ terminalView: TerminalView) -> UIView? {
        terminalInputAccessoryView
    }

    func terminalViewRequestInputAccessoryViewController(_ terminalView: TerminalView) -> UIInputViewController? {
        nil
    }

    func terminalViewDidChangeMode(_ terminalView: TerminalView) {
        let title: String
        switch terminalView.mode {
        case .input: title = "Mode: input"
        case .scroll: title = "Mode: scroll"
        }
        terminalModeChangeButton.setTitle(title, for: .normal)
    }

}

extension SSHTerminalViewController: KeyboardPickerDelegate {
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
