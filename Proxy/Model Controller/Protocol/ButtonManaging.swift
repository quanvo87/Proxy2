import UIKit
import ViewGlower

typealias ButtonManaging = ButtonOwning & ButtonAnimating

protocol ButtonOwning: class {
    var makeNewMessageButton: UIBarButtonItem { get set }
    var makeNewProxyButton: UIBarButtonItem { get set }
}

protocol ButtonAnimating: ButtonOwning {
    var viewGlower: ViewGlower { get }
}

extension ButtonAnimating {
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
