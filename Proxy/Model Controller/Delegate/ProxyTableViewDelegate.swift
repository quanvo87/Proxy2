import UIKit

class ProxyTableViewDelegate: NSObject {
    private weak var convosManager: ConvosManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private weak var controller: UIViewController?

    func load(convosManager: ConvosManaging, unreadMessagesManager: UnreadMessagesManaging?, controller: UIViewController?) {
        self.convosManager = convosManager
        self.unreadMessagesManager = unreadMessagesManager
        self.controller = controller
    }
}

extension ProxyTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            indexPath.section == 1,
            let row = tableView.indexPathForSelectedRow?.row,
            let convo = convosManager?.convos[safe: row] else {
                return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        controller?.navigationController?.showConvoViewController(convo: convo, unreadMessagesManager: unreadMessagesManager)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return CGFloat.leastNormalMagnitude
        case 1:
            return 15
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 140
        case 1:
            return 80
        default:
            return 0
        }
    }
}
