import UIKit

class ConvosTableViewDelegate: NSObject {
    private weak var convosManager: ConvosManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private weak var controller: UIViewController?
  
    func load(convosManager: ConvosManaging, unreadMessagesManager: UnreadMessagesManaging, controller: UIViewController?) {
        self.convosManager = convosManager
        self.unreadMessagesManager = unreadMessagesManager
        self.controller = controller
    }
}

extension ConvosTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let convo = convosManager?.convos[safe: indexPath.row] else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        controller?.navigationController?.showConvoViewController(convo: convo, unreadMessagesManager: unreadMessagesManager)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
