import UIKit

protocol MakeNewMessageDelegate: class {
    var newConvo: Convo? { get set }
}

extension MakeNewMessageDelegate where Self: UIViewController {
    func showMakeNewMessageController(_ sender: Proxy? = nil) {
        guard let makeNewMessageController = UIStoryboard.storyboard.instantiateViewController(withIdentifier: Name.makeNewMessageViewController) as? MakeNewMessageViewController else { return }
        makeNewMessageController.delegate = self
        makeNewMessageController.sender = sender
        let navigationController = UINavigationController(rootViewController: makeNewMessageController)
        present(navigationController, animated: true)
    }
}
