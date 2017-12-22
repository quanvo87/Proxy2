import UIKit

class ProxiesTableViewDelegate: NSObject {
    private weak var proxiesManager: ProxiesManaging?
    private weak var itemsToDeleteManager: ItemsToDeleteManaging?
    private weak var controller: UIViewController?

    func load(proxiesManager: ProxiesManaging, itemsToDeleteManager: ItemsToDeleteManaging, controller: UIViewController?) {
        self.proxiesManager = proxiesManager
        self.itemsToDeleteManager = itemsToDeleteManager
        self.controller = controller
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
            controller?.showProxyController(proxy)
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
