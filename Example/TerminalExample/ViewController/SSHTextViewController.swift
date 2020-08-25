// respect:
// https://github.com/NMSSH/NMSSH/blob/28a3b8a2c9caf5a15d37c5c6dd9d415dda6a03f4/Examples/PTYExample/PTYExample/NMTerminalViewController.m

import UIKit
import NMSSH

final class SSHTextViewController: UIViewController {

    fileprivate var lastCommand: String = ""

    fileprivate let sshQueue = DispatchQueue(label: "NMSSH.queue.SSHTextViewController")
    fileprivate var session: NMSSHSession?
    fileprivate var channel: NMSSHChannel? { session?.channel }

    @IBOutlet private var userNameTextField: UITextField!
    @IBOutlet private var hostNameTextField: UITextField!
    @IBOutlet private var passwordTextField: UITextField!
    @IBOutlet private var textView: UITextView!
    @IBOutlet private var actionBarButtonItem: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        hostNameTextField?.text = UserDefaults.standard.string(forKey: kSSHHostNameDefaultsKey)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        disconnect()
    }

    fileprivate func changeTextViewEditableOnMainThread(_ isEditable: Bool) {
        let execute: () -> Void = { [weak self] in
            guard let textView = self?.textView else {
                return
            }
            textView.isEditable = isEditable
        }
        if Thread.isMainThread {
            execute()
        } else {
            DispatchQueue.main.async(execute: execute)
        }
    }

    fileprivate func appendTextOnMainThread(_ text: String) {
        let execute: () -> Void = { [weak self] in
            guard let textView = self?.textView, let currentText = textView.text else {
                return
            }
            let newText = currentText + text
            textView.text = newText
            textView.scrollRangeToVisible(NSRange(location: newText.count - 1, length: 1))
            textView.selectedRange = NSRange(location: newText.count, length: 0)
        }
        if Thread.isMainThread {
            execute()
        }
        DispatchQueue.main.async(execute: execute)
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

    @IBAction private func handleActionBarButtonItem(_ sender: UIBarButtonItem) {
        if session?.isConnected ?? false {
            disconnect()
        } else {
            connect()
        }
    }

    private func connect() {
        changeTextViewEditableOnMainThread(false)
        guard let user = userNameTextField?.text, let host = hostNameTextField?.text, let pass = passwordTextField?.text else {
            return
        }

        UserDefaults.standard.set(host, forKey: kSSHHostNameDefaultsKey)
        UserDefaults.standard.synchronize()

        sshQueue.async {
            let session = NMSSHSession.connect(toHost: host, withUsername: user)
            self.session = session
            session.delegate = self
            if session.isConnected == false {
                self.appendTextOnMainThread("[ERROR] connection failed.\n")
                self.changeTextViewEditableOnMainThread(false)
                return
            }

            self.appendTextOnMainThread("[INFO] connected: " + session.username + "@" + host + "\n")

            session.authenticate(byPassword: pass)
            if session.isAuthorized == false {
                self.appendTextOnMainThread("[ERROR] authentication failed.\n")
                self.changeTextViewEditableOnMainThread(false)
                return
            }

            self.appendTextOnMainThread("[INFO] authenticate success.\n")

            session.channel.delegate = self
            session.channel.requestPty = true

            do {
                try session.channel.startShell()
                self.changeTextViewEditableOnMainThread(true)
                self.changeBarButtonItemTitleOnMainThread("Disconnect")
            } catch let e {
                let message = "[ERROR] " + e.localizedDescription + "\n"
                self.appendTextOnMainThread(message)
                self.changeTextViewEditableOnMainThread(false)
            }
        }
    }

    private func disconnect() {
        sshQueue.async {
            if let session = self.session {
                session.disconnect()
            }
            self.session = nil // 使い回すとおかしくなるっぽい。
        }
        changeTextViewEditableOnMainThread(false)
        self.changeBarButtonItemTitleOnMainThread("Connect")
    }

    fileprivate func performCommand() {
        let command = lastCommand
        sshQueue.async {
            guard let channel = self.channel else {
                return
            }
            var error: NSError?
            channel.write(command, error: &error, timeout: NSNumber(value: 10))
        }
        lastCommand = ""
    }

}

extension SSHTextViewController: NMSSHSessionDelegate {

    func session(_ session: NMSSHSession, shouldConnectToHostWithFingerprint fingerprint: String) -> Bool {
        self.appendTextOnMainThread("[INFO][session:shouldConnectToHostWithFingerprint:] fingerprint: \(fingerprint)\n")
        return true
    }

    /*
    func session(_ session: NMSSHSession, keyboardInteractiveRequest request: String) -> String {
        return password
    }
     */

    func session(_ session: NMSSHSession, didDisconnectWithError error: Error) {
        let message = "\n[ERROR] " + error.localizedDescription + "\n"
        self.appendTextOnMainThread(message)
        self.changeTextViewEditableOnMainThread(false)
        self.changeBarButtonItemTitleOnMainThread("Connect")
    }

}

extension SSHTextViewController: NMSSHChannelDelegate {

    func channel(_ channel: NMSSHChannel, didReadData message: String) {
        let replace = message.replacingOccurrences(of: "\r", with: "")
        appendTextOnMainThread(replace)
    }

    func channel(_ channel: NMSSHChannel, didReadError error: String) {
        let replace = error.replacingOccurrences(of: "\r", with: "")
        appendTextOnMainThread("\n[ERROR] \(replace)\n")
    }

    func channelShellDidClose(_ channel: NMSSHChannel) {
        appendTextOnMainThread("\n[INFO] Shell Closed.\n")
        changeTextViewEditableOnMainThread(false)
    }

}

extension SSHTextViewController: UITextViewDelegate {

    func textViewDidChange(_ textView: UITextView) {
        textView.scrollRangeToVisible(NSRange(location: textView.text.count - 1, length: 1))
    }

    /*
    func textViewDidChangeSelection(_ textView: UITextView) {
        // textView.selectedRange = NSRange(location: textView.text.count, length: 0)
    }
     */

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if range.location == textView.text.count - 1 && range.length == 1 && text.count == 0 {
            if lastCommand.count > 0 {
                lastCommand.removeLast()
                return true
            } else {
                return false
            }
        } else if range.location != textView.text.count {
            return false
        }

        lastCommand.append(text)
        if text == "\n" {
            performCommand()
        }
        return true
    }

}
