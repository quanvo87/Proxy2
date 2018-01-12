import UIKit

class ProxyTableViewDelegate: NSObject {
    private weak var controller: UIViewController?
    private weak var convosManager: ConvosManaging?
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?

    func load(controller: UIViewController?,
              convosManager: ConvosManaging,
              presenceManager: PresenceManaging,
              proxiesManager: ProxiesManaging,
              unreadMessagesManager: UnreadMessagesManaging) {
        self.convosManager = convosManager
        self.controller = controller
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager
    }
}

extension ProxyTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            indexPath.section == 1,
            let row = tableView.indexPathForSelectedRow?.row,
            let convo = convosManager?.convos[safe: row],
            let presenceManager = presenceManager,
            let proxiesManager = proxiesManager,
            let unreadMessagesManager = unreadMessagesManager else {
                return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        controller?.navigationController?.showConvoViewController(convo: convo, presenceManager: presenceManager, proxiesManager: proxiesManager, unreadMessagesManager: unreadMessagesManager)
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

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard
            indexPath.section == 1,
            let convoCount = convosManager?.convos.count,
            indexPath.row == convoCount - 1,
            let convo = convosManager?.convos[safe: indexPath.row] else {
                return
        }
        convosManager?.loadConvos(endingAtTimestamp: convo.timestamp)
    }
}
