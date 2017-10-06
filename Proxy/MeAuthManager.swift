import UIKit

class MeAuthManager: AuthManaging {
    let observer = AuthObserver()
    weak var controller: MeTableViewController?
    weak var storyboard: UIStoryboard?

    func load(_ controller: MeTableViewController) {
        self.controller = controller
        self.storyboard = controller.storyboard
        observer.observe(self)
    }

    func logIn() {
        guard let controller = controller else { return }
        controller.navigationItem.title = Shared.shared.userName
        controller.messagesReceivedManager.load(tableView: controller.tableView, uid: Shared.shared.uid)
        controller.messagesSentManager.load(tableView: controller.tableView, uid: Shared.shared.uid)
        controller.proxiesInteractedWithManager.load(tableView: controller.tableView, uid: Shared.shared.uid)
    }
}
