import UIKit
import ViewGlower

typealias ButtonManaging = ButtonOwning & ButtonEditing

@objc protocol ButtonOwning {
    var makeNewMessageButton: UIBarButtonItem { get set }
    var makeNewProxyButton: UIBarButtonItem { get set }
}

protocol ButtonEditing: ButtonOwning {
    var viewGlower: ViewGlower { get }
}

extension ButtonEditing {
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
