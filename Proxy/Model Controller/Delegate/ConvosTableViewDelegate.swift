import UIKit

class ConvosTableViewDelegate: NSObject {
    private weak var controller: UIViewController?
    private weak var convosManager: ConvosManager?
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var proxyKeysManager: ProxyKeysManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
  
    func load(controller: UIViewController,
              convosManager: ConvosManager,
              presenceManager: PresenceManaging,
              proxiesManager: ProxiesManaging,
              proxyKeysManager: ProxyKeysManaging,
              unreadMessagesManager: UnreadMessagesManaging) {
        self.controller = controller
        self.convosManager = convosManager
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.proxyKeysManager = proxyKeysManager
        self.unreadMessagesManager = unreadMessagesManager
    }
}

extension ConvosTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let convo = convosManager?.convos[safe: indexPath.row],
            let presenceManager = presenceManager,
            let proxiesManager = proxiesManager,
            let proxyKeysManager = proxyKeysManager,
            let unreadMessagesManager = unreadMessagesManager else {
                return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        controller?.navigationController?.showConvoViewController(convo: convo, presenceManager: presenceManager, proxiesManager: proxiesManager, proxyKeysManager: proxyKeysManager, unreadMessagesManager: unreadMessagesManager)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard
            let convoCount = convosManager?.convos.count,
            indexPath.row == convoCount - 1,
            let convo = convosManager?.convos[safe: indexPath.row] else {
                return
        }
        convosManager?.loadConvos(endingAtTimestamp: convo.timestamp, querySize: Setting.querySize)
    }
}
