import UIKit

typealias ButtonManaging = ButtonOwning & ButtonEditing

@objc protocol ButtonOwning {
    var makeNewMessageButton: UIBarButtonItem { get set }
    var makeNewProxyButton: UIBarButtonItem { get set }
}

protocol ButtonEditing: ButtonOwning {
    var viewGlower: ViewGlower { get }
}

extension ButtonEditing {
    func animateButton(_ button: UIBarButtonItem, loop: Bool = false) {
        button.morph(loop: loop)
        if loop {
            viewGlower.glow(button.customView)
        } else {
            viewGlower.stopGlowing(button.customView)
        }
    }

    func stopAnimatingButton(_ button: UIBarButtonItem) {
        
    }
}
