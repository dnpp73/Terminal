import UIKit
import WebKit

private func onMain(execute: @escaping (() -> Void)) {
    if Thread.isMainThread {
        execute()
    } else {
        DispatchQueue.main.async(execute: execute)
    }
}

final class HtermWebView: WKWebView {

    private(set) var isHtermLoaded: Bool = false {
        didSet {
            if isHtermLoaded == true {
                if oldValue == false {
                    reloadHtermColors()
                }
                terminalView.delegate?.terminalViewDidLoad(terminalView)
            }
        }
    }

    private(set) var terminalSize: TerminalSize = .zero {
        didSet {
            if oldValue != terminalSize {
                terminalView.delegate?.terminalView(terminalView, didChangeTerminalSize: oldValue)
            }
        }
    }

    private(set) var isHtermFocused: Bool = false

    var isContentEditable: Bool = false {
        didSet {
            if isHtermLoaded, oldValue != isContentEditable {
                evaluateJavaScript("term.scrollPort_.getScreenNode().contentEditable = \(isContentEditable)")
            }
        }
    }

    override var backgroundColor: UIColor? {
        didSet {
            if isHtermLoaded, oldValue != backgroundColor {
                evaluateOneArgumentJavaScript(functionName: "term.setBackgroundColor", arg: (backgroundColor ?? .clear).cssString)
            }
        }
    }

    var foregroundColor: UIColor = .clear {
        didSet {
            if isHtermLoaded, oldValue != foregroundColor {
                evaluateOneArgumentJavaScript(functionName: "term.setForegroundColor", arg: foregroundColor.cssString)
            }
        }
    }

    var cursorColor: UIColor = .clear {
        didSet {
            if isHtermLoaded, oldValue != cursorColor {
                evaluateOneArgumentJavaScript(functionName: "term.setCursorColor", arg: cursorColor.cssString)
            }
        }
    }

    var isCursorBlink: Bool = false {
        didSet {
            if isHtermLoaded, oldValue != isCursorBlink {
                evaluateOneArgumentJavaScript(functionName: "term.setCursorBlink", arg: isCursorBlink)
            }
        }
    }

    var cursorShape: TerminalCursorShape = .beam {
        didSet {
            if isHtermLoaded, oldValue != cursorShape {
                evaluateOneArgumentJavaScript(functionName: "term.setCursorShape", arg: cursorShape.rawValue)
            }
        }
    }

    var fontFamily: String = "Menlo" {
        didSet {
            if isHtermLoaded, oldValue != fontFamily {
                evaluateOneArgumentJavaScript(functionName: "exports.setFontFamily", arg: fontFamily)
            }
        }
    }

    var fontSize: UInt = 9 {
        didSet {
            if isHtermLoaded, oldValue != fontSize, 2 <= fontSize, fontSize <= 100 {
                evaluateOneArgumentJavaScript(functionName: "term.setFontSize", arg: fontSize)
            }
        }
    }

    var isEnableBold: Bool? {
        didSet {
            if isHtermLoaded, oldValue != isEnableBold {
                evaluateOneArgumentJavaScript(functionName: "exports.setEnableBold", arg: isEnableBold)
            }
        }
    }

    var isEnableBoldAsBright: Bool = true {
        didSet {
            if isHtermLoaded, oldValue != isEnableBoldAsBright {
                evaluateOneArgumentJavaScript(functionName: "exports.setEnableBoldAsBright", arg: isEnableBoldAsBright)
            }
        }
    }

    // MARK: - Private Vars

    weak var parent: TerminalView?

    // shorthand
    private var terminalView: TerminalView {
        guard let terminalView = parent else {
            fatalError("must not here")
        }
        return terminalView
    }

    fileprivate var shouldEnterInputModeWhenJSTouchEnd: Bool = false

    // MARK: - Initializer

    deinit {
        for bridgingFunction in HtermBridgingFunction.allCases {
            let name = bridgingFunction.rawValue
            configuration.userContentController.removeScriptMessageHandler(forName: name)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init?(code: NSCode) is forbidden. use init(frame: CGRect) instead")
    }

    @available(*, unavailable)
    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        fatalError("init?(frame: CGRect, configuration: WKWebViewConfiguration) is forbidden. use init(frame: CGRect) instead")
    }

    init(frame: CGRect) {
        let configuration = WKWebViewConfiguration.htermConfiguration()
        super.init(frame: frame, configuration: configuration)

        isOpaque = false
        isUserInteractionEnabled = false
        scrollView.isScrollEnabled = false
        scrollView.delaysContentTouches = false
        scrollView.panGestureRecognizer.isEnabled = false
        backgroundColor = .clear // default
        scrollView.backgroundColor = .clear

        allowsLinkPreview = false

        for bridgingFunction in HtermBridgingFunction.allCases {
            let name = bridgingFunction.rawValue
            configuration.userContentController.add(self, name: name)
        }
    }

    // MARK: - UIResponder

    override var canBecomeFirstResponder: Bool { false }
    override var canResignFirstResponder: Bool { false }
    // override var canBecomeFocused: Bool { false }

    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if isHtermLoaded == false {
            return false
        }
        switch action {
        case #selector(UIResponderStandardEditActions.copy(_:)):
            return super.canPerformAction(action, withSender: sender)
        case #selector(UIResponderStandardEditActions.select(_:)):
            return super.canPerformAction(action, withSender: sender)
        case #selector(UIResponderStandardEditActions.selectAll(_:)):
            return super.canPerformAction(action, withSender: sender)
        case #selector(UIResponderStandardEditActions.cut(_:)):
            return false
        case #selector(UIResponderStandardEditActions.paste(_:)):
            return false
        case #selector(UIResponderStandardEditActions.delete(_:)):
            return false
        case #selector(UIResponderStandardEditActions.increaseSize(_:)):
            return false
        case #selector(UIResponderStandardEditActions.decreaseSize(_:)):
            return false
        default:
            // debugLog("action: \(action.description), sender: \(sender.debugDescription )")
            // return super.canPerformAction(action, withSender: sender)
            return false
        }
    }

    // MARK: - UIResponderStandardEditActions

    override public func copy(_ sender: Any?) {
        guard isHtermLoaded else {
            return
        }
        evaluateJavaScript("term.getSelectionText()") { (result: Any?, error: Error?) -> Void in
            if let error = error {
                print("[ERROR] [HtermWebView.htermCopyAll(): term.getSelectionText()] error: \(error)")
                return
            }
            guard let result = result as? String else {
                print("[ERROR] [HtermWebView.htermCopyAll(): term.getSelectionText] result is not String")
                return
            }
            UIPasteboard.general.string = result
        }
    }

    override func select(_ sender: Any?) {
        guard isHtermLoaded else {
            return
        }
        super.select(sender)
    }

    override func selectAll(_ sender: Any?) {
        guard isHtermLoaded else {
            return
        }
        super.selectAll(sender)
    }

    // MARK: - UITraitEnvironment

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *) {
            if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                reloadHtermColors()
            }
        }
    }

    // MARK: - Custom Methods

    private func loadBundleHTML() {
        if let url = Bundle(for: Self.self).url(forResource: "hterm", withExtension: "html") {
            loadFileURL(url, allowingReadAccessTo: url)
        }
    }

    private func reloadHtermColors() {
        guard isHtermLoaded else {
            return
        }
        evaluateOneArgumentJavaScript(functionName: "term.setBackgroundColor", arg: (backgroundColor ?? .clear).cssString)
        evaluateOneArgumentJavaScript(functionName: "term.setForegroundColor", arg: foregroundColor.cssString)
        evaluateOneArgumentJavaScript(functionName: "term.setCursorColor", arg: cursorColor.cssString)
        evaluateOneArgumentJavaScript(functionName: "term.setFontSize", arg: fontSize)
    }

    func reloadHterm() {
        terminalSize = .zero
        htermBlur()
        isHtermLoaded = false
        stopLoading()
        loadBundleHTML()
        // reloadHtermColors will call isHtermLoaded's didSet
    }

}

// MARK: - JavaScript -> Native

// for `webkit.messageHandlers[prop].postMessage(args);`
private enum HtermBridgingFunction: String, CaseIterable {
    case log

    case htermDidLoad

    case htermDidFocusScreen
    case htermDidBlurScreen

    case htermScrollPortDidTouchStart
    case htermScrollPortDidTouchMove
    case htermScrollPortDidTouchEnd
    case htermScrollPortDidTouchCancel

    case htermDidHandleURL

    case htermHandleSendString
    case htermHandleOnVTKeyStroke
    case htermHandleOnTerminalResize
}

extension HtermWebView: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let bridgingFunction = HtermBridgingFunction(rawValue: message.name) else {
            return
        }
        onMain {
            switch bridgingFunction {
            case .log:
                print("\(message.body)")
            case .htermDidLoad:
                self.isHtermLoaded = true
                self.setNeedsLayout()
            case .htermDidFocusScreen:
                self.isHtermFocused = true
            case .htermDidBlurScreen:
                self.isHtermFocused = false
            case .htermScrollPortDidTouchStart:
                self.shouldEnterInputModeWhenJSTouchEnd = true
            case .htermScrollPortDidTouchMove:
                self.shouldEnterInputModeWhenJSTouchEnd = false
            case .htermScrollPortDidTouchEnd:
                if self.shouldEnterInputModeWhenJSTouchEnd {
                    self.shouldEnterInputModeWhenJSTouchEnd = false
                    self.terminalView.enterInputMode()
                }
            case .htermScrollPortDidTouchCancel:
                self.shouldEnterInputModeWhenJSTouchEnd = false
            case .htermDidHandleURL:
                if let body = message.body as? String, let url = URL(string: body) {
                    self.terminalView.delegate?.terminalView(self.terminalView, didHandleURL: url)
                }
            case .htermHandleSendString:
                guard let string = message.body as? String else {
                    break
                }
                self.terminalView.delegate?.terminalView(self.terminalView, didHandleSendString: string)
                self.setUserGesture()
            case .htermHandleOnVTKeyStroke:
                guard let string = message.body as? String else {
                    break
                }
                self.terminalView.delegate?.terminalView(self.terminalView, didHandleOnVTKeyStroke: string)
                self.setUserGesture()
            case .htermHandleOnTerminalResize:
                guard let array = message.body as? [Any] else {
                    break
                }
                guard array.count == 2 else {
                    break
                }
                guard let cols = array[0] as? Int, let rows = array[1] as? Int else {
                    break
                }
                self.terminalSize = TerminalSize(cols: cols, rows: rows)
            }
        }
    }
}

// MARK: - Native -> JavaScript

enum HtermScrollFunction: String {
    case home = "term.scrollHome()"
    case end = "term.scrollEnd()"
    case pageUp = "term.scrollPageUp()"
    case pageDown = "term.scrollPageDown()"
    case lineUp = "term.scrollLineUp()"
    case lineDown = "term.scrollLineDown()"
}

enum HtermClearFunction: String {
    case clearScrollback = "term.clearScrollback()"
    case reset = "term.reset()"
    case softReset = "term.softReset()"
    case clearHome = "term.clearHome()"
    case clear = "term.clear()"
}

enum HtermEraseFunction: String {
    case toLeft = "term.eraseToLeft()"
    case toRight = "term.eraseToRight()"
    case line = "term.eraseLine()"
    case above = "term.eraseAbove()"
    case below = "term.eraseBelow()"
}

extension HtermWebView {

    func htermFocus() {
        guard isHtermLoaded && isHtermFocused == false else {
            return
        }
        evaluateJavaScript("term.focus()") { (_, error: Error?) -> Void in
            onMain {
                if let error = error {
                    print("[ERROR] [HtermWebView.htermFocus()] error: \(error)")
                    return
                }
                self.isHtermFocused = true
            }
        }
    }

    func htermBlur() {
        guard isHtermLoaded && isHtermFocused == true else {
            return
        }
        evaluateJavaScript("term.blur()") { (_, error: Error?) -> Void in
            onMain {
                if let error = error {
                    print("[ERROR] [HtermWebView.htermBlur()] error: \(error)")
                    return
                }
                self.isHtermFocused = false
            }
        }
    }

    func write(_ data: Data) {
        guard isHtermLoaded else {
            return
        }
        guard let str = String(data: data, encoding: .utf8) else {
            return
        }
        // hterm uses UTF-16 by version 1.85 or later. but I think it's JavaScript world... maybe safe `.utf8`
        // Do wee need `data = removeInvalidUTF8(data)` ?
        evaluateOneArgumentJavaScript(functionName: "exports.write", arg: str)
    }

    func syncTerminalSize() {
        guard isHtermLoaded else {
            return
        }
        evaluateJavaScript("exports.syncTerminalSize()") { (result: Any?, error: Error?) -> Void in
            if let error = error {
                print("[ERROR] [HtermWebView.syncTerminalSize()] error: \(error)")
                return
            }
            guard let result = result as? [Int] else {
                print("[ERROR] [HtermWebView.syncTerminalSize()] result is not Array<Int>")
                return
            }
            onMain {
                let cols = result[0]
                let rows = result[1]
                self.terminalSize = TerminalSize(cols: cols, rows: rows)
            }
        }
    }

    func clearSelection(completionHandler: ((Any?, Error?) -> Void)? = nil) {
        guard isHtermLoaded else {
            return
        }
        evaluateJavaScript("exports.clearSelection()", completionHandler: completionHandler)
    }

    func htermScroll(_ function: HtermScrollFunction) {
        guard isHtermLoaded else {
            return
        }
        evaluateJavaScript(function.rawValue)
    }

    func htermClear(_ function: HtermClearFunction) {
        guard isHtermLoaded else {
            return
        }
        evaluateJavaScript(function.rawValue)
    }

    func htermErase(_ function: HtermEraseFunction) {
        guard isHtermLoaded else {
            return
        }
        evaluateJavaScript(function.rawValue)
    }

    func setUserGesture() {
        guard isHtermLoaded else {
            return
        }
        evaluateJavaScript("exports.setUserGesture()")
    }

    func getVisibleText(callback: @escaping ((String) -> Void)) {
        guard isHtermLoaded else {
            callback("")
            return
        }
        evaluateJavaScript("exports.getVisibleText()") { (result: Any?, error: Error?) -> Void in
            onMain {
                if let error = error {
                    print("[ERROR] [HtermWebView.getVisibleText(): exports.getVisibleText()] error: \(error)")
                    callback("")
                    return
                }
                guard let result = result as? String else {
                    print("[ERROR] [HtermWebView.getVisibleText(): exports.getVisibleText()] result is not String")
                    callback("")
                    return
                }
                callback(result)
            }
        }
    }

    func getAllText(callback: @escaping ((String) -> Void)) {
        guard isHtermLoaded else {
            callback("")
            return
        }
        evaluateJavaScript("exports.getAllText()") { (result: Any?, error: Error?) -> Void in
            onMain {
                if let error = error {
                    print("[ERROR] [HtermWebView.getAllText(): exports.getAllText()] error: \(error)")
                    callback("")
                    return
                }
                guard let result = result as? String else {
                    print("[ERROR] [HtermWebView.getAllText(): exports.getAllText()] result is not String")
                    callback("")
                    return
                }
                callback(result)
            }
        }
    }

}
