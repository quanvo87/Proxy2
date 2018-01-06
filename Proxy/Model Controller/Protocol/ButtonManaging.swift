import UIKit
import ViewGlower

protocol ButtonManaging: class {
    var makeNewMessageButton: UIBarButtonItem { get set }
    var makeNewProxyButton: UIBarButtonItem { get set }
    var viewGlower: ViewGlower { get }
}

extension ButtonManaging {
    func animate(_ button: UIBarButtonItem, loop: Bool = false) {
        button.morph(loop: loop)
        if loop {
            viewGlower.glow(button.customView, to: 0.6, duration: 1.2)
        } else {
            viewGlower.stopGlowing(button.customView)
        }
    }

    func stopAnimating(_ button: UIBarButtonItem) {
        button.customView?.layer.stopAnimating()
        viewGlower.stopGlowing(button.customView)
    }
}
