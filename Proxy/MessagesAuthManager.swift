import UIKit

class MessagesAuthManager: AuthManaging {
    let observer = AuthObserver()
    weak var controller: MessagesTableViewController?

    func load(_ controller: MessagesTableViewController) {
        self.controller = controller
        observer.observe(self)
    }

    func logIn() {
        guard let controller = controller else { return }
        controller.buttonManager.load(controller)
        controller.convosManager.load(convosOwner: Shared.shared.uid, reloader: controller.reloader)
        controller.dataSource.manager = controller.convosManager
        controller.delegate.controller = controller
        controller.unreadCountManager.load(controller)
        Shared.shared.queue.async {
            DBProxy.fixConvoCounts { _ in }
        }
    }
}
