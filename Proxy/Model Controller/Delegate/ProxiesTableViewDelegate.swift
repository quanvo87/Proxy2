import UIKit

class ProxiesTableViewDelegate: NSObject {
    private weak var controller: UIViewController?
    private weak var itemsToDeleteManager: ItemsToDeleteManaging?
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?

    init(controller: UIViewController?,
         itemsToDeleteManager: ItemsToDeleteManaging?,
         presenceManager: PresenceManaging?,
         proxiesManager: ProxiesManaging?,
         unreadMessagesManager: UnreadMessagesManaging?) {
        self.controller = controller
        self.itemsToDeleteManager = itemsToDeleteManager
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager
    }
}

extension ProxiesTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = proxiesManager?.proxies[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            itemsToDeleteManager?.itemsToDelete[proxy.key] = proxy
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            controller?.showProxyController(proxy: proxy,
                                            presenceManager: presenceManager,
                                            proxiesManager: proxiesManager,
                                            unreadMessagesManager: unreadMessagesManager)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard
            tableView.isEditing,
            let proxy = proxiesManager?.proxies[safe: indexPath.row] else {
                return
        }
        itemsToDeleteManager?.itemsToDelete.removeValue(forKey: proxy.key)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
