import UIKit

protocol KeyboardPickerDelegate: AnyObject {
    func keyboardPicker(_ keyboardPicker: KeyboardPicker, didSelect index: Int)
}

class KeyboardPicker: UIButton {

    weak var delegate: KeyboardPickerDelegate?

    var dataSource: [String] = []

    var selectedIndex: Int {
        get {
            lastSelectedIndex
        }
        set {
            lastSelectedIndex = newValue
            pickerView?.selectRow(newValue, inComponent: 0, animated: false)
        }
    }

    var selectedData: String {
        get {
            dataSource[lastSelectedIndex]
        }
        set {
            let index = dataSource.firstIndex(of: newValue) ?? 0
            lastSelectedIndex = index
            pickerView?.selectRow(index, inComponent: 0, animated: false)
        }
    }

    weak var pickerView: UIPickerView?

    private var lastSelectedIndex: Int = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        addTarget(self, action: #selector(touchUpInsideSelf(_:)), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        addTarget(self, action: #selector(touchUpInsideSelf(_:)), for: .touchUpInside)
    }

    @objc
    private func touchUpInsideSelf(_ sender: KeyboardPicker) {
        becomeFirstResponder()
    }

    override var canBecomeFirstResponder: Bool {
        true
    }

    override var inputView: UIView? {
        let pickerView: UIPickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.selectRow(lastSelectedIndex, inComponent: 0, animated: false)
        pickerView.autoresizingMask = [.flexibleHeight]
        self.pickerView = pickerView

        // SafeArea 対応をする為に UIView を挟む
        let view = UIView()
        view.autoresizingMask = [.flexibleHeight]
        view.addSubview(pickerView)

        pickerView.translatesAutoresizingMaskIntoConstraints = false
        pickerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        pickerView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        pickerView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor).isActive = true

        return view
    }

    override var inputAccessoryView: UIView? {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        view.frame = CGRect(x: 0, y: 0, width: frame.width, height: 44)

        let closeButton = UIButton(type: .custom)
        closeButton.setTitle("Close", for: .normal)
        closeButton.sizeToFit()
        closeButton.addTarget(self, action: #selector(touchUpInsideCloseButton(_:)), for: .touchUpInside)

        view.contentView.addSubview(closeButton)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.widthAnchor.constraint(equalToConstant: closeButton.frame.size.width).isActive = true
        closeButton.heightAnchor.constraint(equalToConstant: closeButton.frame.size.height).isActive = true
        closeButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 5).isActive = true
        closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true

        return view
    }

    @objc
    private func touchUpInsideCloseButton(_ sender: UIButton) {
        resignFirstResponder()
    }

}

extension KeyboardPicker: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        dataSource.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        dataSource[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        lastSelectedIndex = row
        delegate?.keyboardPicker(self, didSelect: row)
    }

}
