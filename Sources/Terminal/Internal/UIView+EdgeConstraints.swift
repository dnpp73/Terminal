import UIKit

extension UIView {

    func addConstraintsToEdges(_ targetView: UIView) {
        // should be fail when invalid UIView hierarchy.
        translatesAutoresizingMaskIntoConstraints = false
        leftAnchor.constraint(equalTo: targetView.leftAnchor).isActive = true
        rightAnchor.constraint(equalTo: targetView.rightAnchor).isActive = true
        topAnchor.constraint(equalTo: targetView.topAnchor).isActive = true
        bottomAnchor.constraint(equalTo: targetView.bottomAnchor).isActive = true
    }

    func addConstraintsToSuperviewEdges() {
        // This is safe.
        guard let superview = superview else {
            return
        }
        addConstraintsToEdges(superview)
    }

}
