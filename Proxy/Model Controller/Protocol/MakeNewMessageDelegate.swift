import UIKit

protocol MakeNewMessageDelegate: class {
    var newConvo: Convo? { get set }
}

extension MakeNewMessageDelegate {
    func showMakeNewMessageController(controller: UIViewController?, sender: Proxy?, uid: String) {
        guard let viewController = UIStoryboard.storyboard.instantiateViewController(withIdentifier: Name.makeNewMessageViewController) as? MakeNewMessageViewController else { return }
        viewController.load(delegate: self, sender: sender, uid: uid)
        controller?.present(UINavigationController(rootViewController: viewController), animated: true)
    }
}
