import UIKit

class MeAuthManager: AuthManaging {
    private let observer = AuthObserver()
    private weak var controller: MeTableViewController?
    private weak var storyboard: UIStoryboard?

    func load(_ controller: MeTableViewController) {
        self.controller = controller
        self.storyboard = controller.storyboard
        observer.observe(self)
    }

    func logIn() {
        guard let controller = controller else { return }
        controller.navigationItem.title = Shared.shared.userName
        controller.messagesReceivedManager.load(uid: Shared.shared.uid, tableView: controller.tableView)
        controller.messagesSentManager.load(uid: Shared.shared.uid, tableView: controller.tableView)
        controller.proxiesInteractedWithManager.load(uid: Shared.shared.uid, tableView: controller.tableView)
    }
}
