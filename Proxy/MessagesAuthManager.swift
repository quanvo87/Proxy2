import UIKit

class MessagesAuthManager: AuthManaging {
    private let observer = AuthObserver()
    private weak var controller: MessagesTableViewController?

    func load(_ controller: MessagesTableViewController) {
        self.controller = controller
        observer.observe(self)
    }

    func logIn() {
        controller?.logIn()
    }
}
