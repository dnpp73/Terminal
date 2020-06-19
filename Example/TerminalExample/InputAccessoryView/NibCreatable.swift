import UIKit

extension Collection {
    public subscript(safe index: Index) -> Element? {
        startIndex <= index && index < endIndex ? self[index] : nil
    }
}

protocol NibCreatable: AnyObject {
    static var currentBundle: Bundle { get }
    static var nibName: String { get }
    static var nibIndex: Int? { get }
    static var nibOptions: [UINib.OptionsKey: Any]? { get }
    static var nib: UINib { get }
    static func createFromNib(owner: Any?) -> Self?
}

extension NibCreatable {

    static var currentBundle: Bundle { Bundle(for: Self.self) }

    static var nibName: String {
        guard let className = NSStringFromClass(Self.self).components(separatedBy: ".").last else {
            fatalError("NibCreatable could not get valid className for \(Self.self)")
        }
        return className
    }

    static var nibIndex: Int? { nil }

    static var nibOptions: [UINib.OptionsKey: Any]? { nil }

    static var nib: UINib {
        UINib(nibName: nibName, bundle: currentBundle)
    }

    static func createFromNib(owner: Any? = nil) -> Self? {
        guard let bundleContents = currentBundle.loadNibNamed(nibName, owner: owner, options: nibOptions) else {
            return nil
        }
        if let nibIndex = nibIndex {
            guard let instance = bundleContents[safe: nibIndex] as? Self else {
                return nil
            }
            return instance
        } else {
            guard let instance = bundleContents.first(where: { $0 is Self }) as? Self else {
                return nil
            }
            return instance
        }
    }

}
