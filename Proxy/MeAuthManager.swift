import UIKit

class MeAuthManager: AuthManaging {
    private let observer = AuthObserver()
    private weak var controller: MeTableViewController?

    func load(_ controller: MeTableViewController) {
        self.controller = controller
        observer.observe(self)
    }

    func logIn() {
        controller?.logIn()
        controller?.navigationItem.title = Shared.shared.userName
    }
}
