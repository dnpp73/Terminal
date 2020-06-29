import UIKit
import WebKit

public enum TerminalMode {
    case input
    case scroll
}

public enum TerminalCursorShape: String {
    case block = "BLOCK"
    case beam = "BEAM"
    case underline = "UNDERLINE"
}

public protocol TerminalViewDelegate: AnyObject {
    func terminalViewDidLoad(_ terminalView: TerminalView)

    func terminalView(_ terminalView: TerminalView, didChangeTerminalSize oldSize: TerminalSize)
    func terminalView(_ terminalView: TerminalView, didHandleURL url: URL)

    func terminalView(_ terminalView: TerminalView, didHandleKeyInput string: String)
    func terminalViewDidHandleDeleteBackward(_ terminalView: TerminalView)

    func terminalView(_ terminalView: TerminalView, didHandleSendString string: String)
    func terminalView(_ terminalView: TerminalView, didHandleOnVTKeyStroke string: String)

    func terminalViewRequestInputAccessoryView(_ terminalView: TerminalView) -> UIView?
    func terminalViewRequestInputAccessoryViewController(_ terminalView: TerminalView) -> UIInputViewController?

    func terminalViewDidChangeMode(_ terminalView: TerminalView)
}

public final class TerminalView: UIView {

    // MARK: - Public Vars

    public weak var delegate: TerminalViewDelegate?

    public var isTerminalLoaded: Bool { htermWebView?.isHtermLoaded ?? false }

    public var terminalSize: TerminalSize { htermWebView?.terminalSize ?? .zero }

    public private(set) var mode: TerminalMode = .input {
        didSet {
            if oldValue != mode {
                delegate?.terminalViewDidChangeMode(self)
            }
        }
    }

    // danger... be careful.
    public var isTerminalContentEditable: Bool {
        get { htermWebView?.isContentEditable ?? false }
        set { htermWebView?.isContentEditable = newValue }
    }

    public var isTerminalCursorBlink: Bool {
        get { htermWebView?.isCursorBlink ?? true }
        set { htermWebView?.isCursorBlink = newValue }
    }
    public var terminalCursorShape: TerminalCursorShape {
        get { htermWebView?.cursorShape ?? .beam }
        set { htermWebView?.cursorShape = newValue }
    }

    public var isControlKeyPressed: Bool = false
    public var isMetaKeyPressed: Bool = false

    public var useOptionKeyAsMetaKey: Bool = false {
        didSet {
            registerKeyCommands()
        }
    }

    @IBInspectable public var terminalBackgroundColor: UIColor? {
        get { htermWebView?.backgroundColor }
        set { htermWebView?.backgroundColor = newValue }
    }

    @IBInspectable public var terminalForegroundColor: UIColor? {
        get { htermWebView?.foregroundColor }
        set { htermWebView?.foregroundColor = (newValue ?? .clear) }
    }

    @IBInspectable public var terminalCursorColor: UIColor? {
        get { htermWebView?.cursorColor }
        set { htermWebView?.cursorColor = (newValue ?? .clear) }
    }

    @IBInspectable public var terminalFontFamily: String? {
        get { htermWebView?.fontFamily }
        set { htermWebView?.fontFamily = (newValue ?? "Menlo") }
    }

    @IBInspectable public var terminalFontSize: UInt {
        get { htermWebView?.fontSize ?? 9 }
        set { htermWebView?.fontSize = newValue }
    }

    // true or false or null. Null to autodetect. default null.
    // `nil` will be convert to JavaScript's `null` by JSONEncoder. This is safe.
    public var terminalIsEnableBold: Bool? {
        get { htermWebView?.isEnableBold }
        set { htermWebView?.isEnableBold = newValue }
    }

    public var terminalIsEnableBoldAsBright: Bool {
        get { htermWebView?.isEnableBoldAsBright ?? true }
        set { htermWebView?.isEnableBoldAsBright = newValue }
    }

    // MARK: - Public Vars for UITextInputTraits

    public var keyboardType: UIKeyboardType = .default
    public var keyboardAppearance: UIKeyboardAppearance = .default
    public var returnKeyType: UIReturnKeyType = .default
    public var isSecureTextEntry: Bool = false

    public var autocorrectionType: UITextAutocorrectionType = .no
    public var autocapitalizationType: UITextAutocapitalizationType = .none
    public var spellCheckingType: UITextSpellCheckingType = .no

    public var smartQuotesType: UITextSmartQuotesType = .no
    public var smartDashesType: UITextSmartDashesType = .no
    public var smartInsertDeleteType: UITextSmartInsertDeleteType = .no

    // MARK: - Public Vars for UITextInput IME Hack

    public weak var inputDelegate: UITextInputDelegate?

    // MARK: - Private Vars

    fileprivate var htermWebView: HtermWebView?

    fileprivate var buffer = Data()
    fileprivate let bufferQueue = DispatchQueue(label: "TerminalView.bufferQueue")

    fileprivate var needsTerminalScrollEnd: Bool = false

    private let tapGestureRecognizer = UITapGestureRecognizer()
    private let longPressGestureRecognizer = UILongPressGestureRecognizer()
    private let panGestureRecognizer = UIPanGestureRecognizer()

    // MARK: - Private Vars for UITextInput IME Hack

    fileprivate var markedTextForIMEHack: String?
    fileprivate let markedTextRangeForIMEHack = UITextRange()
    fileprivate let selectedTextRangeForIMEHack = UITextRange()
    fileprivate var textInputStringTokenizerForIMEHack: UITextInputStringTokenizer?

    // MARK: - Private Var for UIKeyCommand

    private var customKeyCommands: [UIKeyCommand] = []

    // MARK: - Initializer

    deinit {
        bufferQueue.sync {
            buffer.removeAll()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        panGestureRecognizer.addTarget(self, action: #selector(handlePanGestureRecognizer(_:)))
        addGestureRecognizer(panGestureRecognizer)

        longPressGestureRecognizer.addTarget(self, action: #selector(handleLongPressGestureRecognizer(_:)))
        addGestureRecognizer(longPressGestureRecognizer)

        tapGestureRecognizer.addTarget(self, action: #selector(handleTapGestureRecognizer(_:)))
        addGestureRecognizer(tapGestureRecognizer)

        let htermWebView = HtermWebView(frame: bounds)
        htermWebView.parent = self
        addSubview(htermWebView)
        htermWebView.addConstraintsToSuperviewEdges()
        self.htermWebView = htermWebView

        textInputStringTokenizerForIMEHack = UITextInputStringTokenizer(textInput: self)

        registerKeyCommands()

        htermWebView.reloadHterm()
    }

    // MARK: - UIView

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard let hterm = htermWebView, hterm.isHtermLoaded else {
            return
        }
        var data: Data?
        bufferQueue.sync {
            data = buffer
            buffer.removeAll()
        }
        if let data = data {
            hterm.write(data)
        }
        hterm.syncTerminalSize()
        if needsTerminalScrollEnd {
            needsTerminalScrollEnd = false
            terminalScroll(.end)
        }
    }

    // MARK: - UIResponder

    override public var canBecomeFirstResponder: Bool { mode == .input }
    override public var canResignFirstResponder: Bool { mode == .input }

    override public func becomeFirstResponder() -> Bool {
        guard let htermWebView = htermWebView else {
            return false
        }
        let accepted = super.becomeFirstResponder()
        if accepted {
            htermWebView.htermFocus()
        }
        return accepted
    }

    override public func resignFirstResponder() -> Bool {
        guard let htermWebView = htermWebView else {
            return false
        }
        let accepted = super.resignFirstResponder()
        if accepted {
            htermWebView.htermBlur()
        }
        return accepted
    }

    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        // debugLog("action: \(action.description), sender: \(sender.debugDescription )")
        if mode != .input {
            return false
        }
        guard let htermWebView = htermWebView else {
            return false
        }
        switch action {
        case #selector(UIResponderStandardEditActions.cut(_:)):
            return false
        case #selector(UIResponderStandardEditActions.copy):
            return false
        case #selector(UIResponderStandardEditActions.paste(_:)):
            if UIPasteboard.general.string?.count ?? 0 > 0 {
                return htermWebView.isHtermLoaded
            } else {
                return false
            }
        case #selector(UIResponderStandardEditActions.delete(_:)):
            return false
        case #selector(UIResponderStandardEditActions.select(_:)):
            return htermWebView.isHtermLoaded
        case #selector(UIResponderStandardEditActions.selectAll(_:)):
            return htermWebView.isHtermLoaded
        case #selector(UIResponderStandardEditActions.increaseSize(_:)):
            return htermWebView.isHtermLoaded
        case #selector(UIResponderStandardEditActions.decreaseSize(_:)):
            return htermWebView.isHtermLoaded
        default:
            return super.canPerformAction(action, withSender: sender)
        }
    }

    override public var inputAccessoryView: UIView? {
        delegate?.terminalViewRequestInputAccessoryView(self)
    }

    override public var inputAccessoryViewController: UIInputViewController? {
        delegate?.terminalViewRequestInputAccessoryViewController(self)
    }

    // MARK: - UIResponderStandardEditActions

    override public func copy(_ sender: Any?) {
        // nop
    }

    override public func paste(_ sender: Any?) {
        if let string = UIPasteboard.general.string {
            handleKeyInput(string)
        }
    }

    override public func select(_ sender: Any?) {
        guard let htermWebView = htermWebView else {
            return
        }
        enterScrollMode()
        // TODO: want to remove magical dispatch_after...
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            htermWebView.select(sender)
        }
    }

    override public func selectAll(_ sender: Any?) {
        guard let htermWebView = htermWebView else {
            return
        }
        enterScrollMode()
        // TODO: want to remove magical dispatch_after...
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            htermWebView.selectAll(sender)
        }
    }

    override public func increaseSize(_ sender: Any?) {
        let size = terminalFontSize + 1
        terminalFontSize = min(size, 30)
    }

    override public func decreaseSize(_ sender: Any?) {
        let size = terminalFontSize - 1
        terminalFontSize = max(size, 2)
    }

    // MARK: - UIKeyCommand

    override public var keyCommands: [UIKeyCommand]? {
        customKeyCommands
    }

    private func registerKeyCommands() {
        customKeyCommands.removeAll()

        let normal: [String] = [
            UIKeyCommand.inputEscape,
            // UIKeyCommand.inputHome, // iOS 13.4 ~
            UIKeyCommand.inputPageUp,
            UIKeyCommand.inputPageDown,
            // UIKeyCommand.inputEnd, // iOS 13.4 ~
            UIKeyCommand.inputLeftArrow,
            UIKeyCommand.inputDownArrow,
            UIKeyCommand.inputUpArrow,
            UIKeyCommand.inputRightArrow,
        ]
        normal.forEach {
            customKeyCommands.append(UIKeyCommand(input: $0, modifierFlags: [], action: #selector(handleKeyCommand(_:))))
        }
        controlKeys.forEach {
            let string = String($0)
            customKeyCommands.append(UIKeyCommand(input: string, modifierFlags: [.control], action: #selector(handleKeyCommand(_:))))
        }
        if useOptionKeyAsMetaKey {
            metaKeys.forEach {
                let string = String($0)
                customKeyCommands.append(UIKeyCommand(input: string, modifierFlags: [.alternate], action: #selector(handleKeyCommand(_:))))
            }
        }

        // Clear
        customKeyCommands.append(UIKeyCommand(input: "k", modifierFlags: .command, action: #selector(handleKeyCommand(_:))))

        // Shft + Tab
        customKeyCommands.append(UIKeyCommand(input: .terminalTab, modifierFlags: .shift, action: #selector(handleKeyCommand(_:))))
    }

    @objc
    private func handleKeyCommand(_ keyCommand: UIKeyCommand) {
        // debugLog(keyCommand.description)
        guard let i = keyCommand.input else {
            return
        }
        if keyCommand.modifierFlags == .command, i == "k" {
            htermWebView?.htermClear(.reset)
        } else if keyCommand.modifierFlags == .shift, i == .terminalTab {
            handleKeyInput(.terminalBackTab)
        } else if keyCommand.modifierFlags == .control, let controlled = i.combineWithControlKey() {
            handleKeyInput(controlled)
        } else if useOptionKeyAsMetaKey, keyCommand.modifierFlags == .alternate, let metaPrefixed = i.combineWithMetaKey() {
            handleKeyInput(metaPrefixed)
        } else {
            switch i {
            case UIKeyCommand.inputEscape:
                handleKeyInput(.terminalEscape)
            case UIKeyCommand.inputPageUp:
                handleKeyInput(.terminalPageUp)
            case UIKeyCommand.inputPageDown:
                handleKeyInput(.terminalPageDown)
            case UIKeyCommand.inputLeftArrow:
                handleKeyInput(.terminalLeftArrow)
            case UIKeyCommand.inputUpArrow:
                handleKeyInput(.terminalUpArrow)
            case UIKeyCommand.inputDownArrow:
                handleKeyInput(.terminalDownArrow)
            case UIKeyCommand.inputRightArrow:
                handleKeyInput(.terminalRightArrow)
            default:
                handleKeyInput(i)
            }
        }
    }

    // MARK: - UIGestureRecognizer

    @objc
    private func handleTapGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        if tapGestureRecognizer == self.tapGestureRecognizer {
            if isFirstResponder == false {
                _ = becomeFirstResponder()
            } else {
                if UIMenuController.shared.isMenuVisible {
                    if #available(iOS 13.0, *) {
                        UIMenuController.shared.hideMenu()
                    } else {
                        UIMenuController.shared.setMenuVisible(false, animated: true)
                    }
                }
            }
        }
    }

    @objc
    private func handleLongPressGestureRecognizer(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        if longPressGestureRecognizer == self.longPressGestureRecognizer {
            if longPressGestureRecognizer.state == .began {
                let menu = UIMenuController.shared
                let p = longPressGestureRecognizer.location(in: self)
                let rect = CGRect(origin: p, size: .zero)
                if #available(iOS 13.0, *) {
                    menu.showMenu(from: self, rect: rect)
                } else {
                    menu.setTargetRect(rect, in: self)
                    menu.setMenuVisible(true, animated: true)
                }
            }
        }
    }

    @objc
    private func handlePanGestureRecognizer(_ panGestureRecognizer: UIPanGestureRecognizer) {
        if panGestureRecognizer == self.panGestureRecognizer {
            if panGestureRecognizer.state == .began {
                if mode != .scroll {
                    enterScrollMode()
                    panGestureRecognizer.cancel()
                }
            }
        }
    }

    // MARK: - Private

    fileprivate func handleKeyInput(_ string: String) {
        setNeedsTerminalScrollEnd()
        // TODO: Research...
        // delegate?.terminalView(self, didHandleKeyInput: string.replacingOccurrences(of: "\n", with: "\r"))
        delegate?.terminalView(self, didHandleKeyInput: string)
        htermWebView?.setUserGesture()
    }

    // MARK: - Public Methods for Input/Scroll Mode Change

    public func enterInputMode() {
        guard mode != .input, let htermWebView = htermWebView else {
            return
        }
        htermWebView.isUserInteractionEnabled = false
        terminalScroll(.end) // no need setNeedsTerminalScrollEnd()
        mode = .input
        _ = becomeFirstResponder() // should after mode setting
    }

    public func enterScrollMode() {
        guard mode != .scroll, let htermWebView = htermWebView else {
            return
        }
        htermWebView.isUserInteractionEnabled = true
        _ = resignFirstResponder() // shoud before mode setting
        mode = .scroll
    }

    // MARK: - Public Methods for Buffer

    public func clearBuffer() {
        bufferQueue.async {
            self.buffer.removeAll()
            DispatchQueue.main.async { [weak self] in
                self?.setNeedsLayout()
            }
        }
    }

    public func appendBuffer(_ buf: Data) {
        bufferQueue.async {
            self.buffer.append(buf)
            DispatchQueue.main.async { [weak self] in
                self?.setNeedsLayout()
            }
        }
    }

    // MARK: - Public Method for Key Down Event

    public func press(_ event: TerminalKeyDownEvent) {
        handleKeyInput(event.string)
    }

    // MARK: - Public Methods for Scroll

    public func setNeedsTerminalScrollEnd() {
        needsTerminalScrollEnd = true
        setNeedsLayout()
    }

    public func terminalScroll(_ event: TerminalScrollEvent) {
        htermWebView?.htermScroll(event.htermFunction)
    }

    // MARK: - Public Method for Clear

    public func terminalClear(_ event: TerminalClearEvent) {
        htermWebView?.htermClear(event.htermFunction)
    }

    // MARK: - Public Method for Erase

    // danger... be careful.
    public func terminalErase(_ event: TerminalEraseEvent) {
        htermWebView?.htermErase(event.htermFunction)
    }

    // MARK: - Public Methods for Force Reload

    public func reloadTerminal() {
        htermWebView?.reloadHterm()
    }

    // MARK: - Get Drawing Text

    public func getVisibleText(callback: @escaping ((String) -> Void)) {
        guard let htermWebView = htermWebView else {
            callback("")
            return
        }
        htermWebView.getVisibleText(callback: callback)
    }

    public func getAllText(callback: @escaping ((String) -> Void)) {
        guard let htermWebView = htermWebView else {
            callback("")
            return
        }
        htermWebView.getAllText(callback: callback)
    }

}

// MARK: - UIKeyInput

extension TerminalView: UIKeyInput {

    public var hasText: Bool {
        guard let htermWebView = htermWebView else {
            return false
        }
        return htermWebView.isHtermLoaded
    }

    public func insertText(_ text: String) {
        if isControlKeyPressed == true, isMetaKeyPressed == false, let controled = text.combineWithControlKey() {
            handleKeyInput(controled)
        } else if isMetaKeyPressed == true, isControlKeyPressed == false, let metaPrefixed = text.combineWithMetaKey() {
            handleKeyInput(metaPrefixed)
        } else {
            handleKeyInput(text)
        }
    }

    public func deleteBackward() {
        delegate?.terminalViewDidHandleDeleteBackward(self)
    }

}

// MARK: - UITextInput

extension TerminalView: UITextInput {

    // MARK: - for IME Hack

    public func text(in range: UITextRange) -> String? {
        if range == markedTextRangeForIMEHack {
            // debugLog("range is markedTextRangeForIMEHack. returning markedTextForIMEHack(\(markedTextForIMEHack ?? "nil"))")
            return markedTextForIMEHack
        } else if range == selectedTextRangeForIMEHack {
            // debugLog("range is selectedTextRangeForIMEHack. returning empty string.")
            return ""
        } else {
            // debugLog("range: \(range)")
            return nil
        }
    }

    public var markedTextRange: UITextRange? {
        if let  _ = markedTextForIMEHack {
            return markedTextRangeForIMEHack
        } else {
            return nil
        }
    }

    public var selectedTextRange: UITextRange? {
        get {
            selectedTextRangeForIMEHack
        }
        set(selectedTextRange) {
            // ignore selectedTextRange
            debugLog("selectedTextRange: \(selectedTextRange?.description ?? "nil")")
        }
    }

    public func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        // debugLog("markedText: \(markedText ?? "nil"), selectedRange: \(selectedRange)")
        markedTextForIMEHack = markedText
    }

    public func unmarkText() {
        // debugLog()
        if let markedText = markedTextForIMEHack {
            markedTextForIMEHack = nil
            handleKeyInput(markedText)
        }
    }

    public var tokenizer: UITextInputTokenizer {
        // debugLog()
        guard let textInputStringTokenizerForIMEHack = textInputStringTokenizerForIMEHack else {
            fatalError("must not here")
        }
        return textInputStringTokenizerForIMEHack
    }

    // MARK: - Stubs for Swift Compiler

    public var markedTextStyle: [NSAttributedString.Key: Any]? {
        get {
            debugLog()
            return nil
        }
        set(markedTextStyle) {
            debugLog("markedTextStyle: \(markedTextStyle?.description ?? "nil")")
        }
    }

    public func replace(_ range: UITextRange, withText text: String) {
        debugLog("range: \(range), text: \(text)")
    }

    public var beginningOfDocument: UITextPosition {
        // debugLog()
        return UITextPosition()
    }

    public var endOfDocument: UITextPosition {
        // debugLog()
        return UITextPosition()
    }

    public func textRange(from fromPosition: UITextPosition, to toPosition: UITextPosition) -> UITextRange? {
        // debugLog("fromPosition: \(fromPosition), toPosition: \(toPosition)")
        return nil
    }

    public func position(from position: UITextPosition, offset: Int) -> UITextPosition? {
        // debugLog("position: \(position), offset: \(offset)")
        return nil
    }

    public func position(from position: UITextPosition, in direction: UITextLayoutDirection, offset: Int) -> UITextPosition? {
        debugLog("position: \(position), direction: \(direction), offset: \(offset)")
        return nil
    }

    public func compare(_ position: UITextPosition, to other: UITextPosition) -> ComparisonResult {
        // debugLog("position: \(position), other: \(other)")
        return .orderedSame
    }

    public func offset(from: UITextPosition, to toPosition: UITextPosition) -> Int {
        debugLog("from: \(from), toPosition: \(toPosition)")
        return Int.max
    }

    public func position(within range: UITextRange, farthestIn direction: UITextLayoutDirection) -> UITextPosition? {
        debugLog("range: \(range), direction: \(direction)")
        return nil
    }

    public func characterRange(byExtending position: UITextPosition, in direction: UITextLayoutDirection) -> UITextRange? {
        debugLog("position: \(position), direction: \(direction)")
        return nil
    }

    public func baseWritingDirection(for position: UITextPosition, in direction: UITextStorageDirection) -> NSWritingDirection {
        debugLog("position: \(position), direction: \(direction)")
        return .leftToRight
    }

    public func setBaseWritingDirection(_ writingDirection: NSWritingDirection, for range: UITextRange) {
        debugLog("writingDirection: \(writingDirection), range: \(range)")
    }

    public func firstRect(for range: UITextRange) -> CGRect {
        // debugLog("range: \(range)")
        return .zero
    }

    public func caretRect(for position: UITextPosition) -> CGRect {
        // debugLog("position: \(position)")
        return .zero
    }

    public func selectionRects(for range: UITextRange) -> [UITextSelectionRect] {
        // debugLog("range: \(range)")
        return []
    }

    public func closestPosition(to point: CGPoint) -> UITextPosition? {
        debugLog("point: \(point)")
        return nil
    }

    public func closestPosition(to point: CGPoint, within range: UITextRange) -> UITextPosition? {
        debugLog("point: \(point), range: \(range)")
        return nil
    }

    public func characterRange(at point: CGPoint) -> UITextRange? {
        debugLog("point: \(point)")
        return nil
    }

}
