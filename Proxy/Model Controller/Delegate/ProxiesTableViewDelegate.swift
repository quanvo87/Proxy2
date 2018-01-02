import UIKit

class ProxiesTableViewDelegate: NSObject {
    private weak var itemsToDeleteManager: ItemsToDeleteManaging?
    private weak var controller: UIViewController?
    private weak var container: DependencyContaining?

    func load(itemsToDeleteManager: ItemsToDeleteManaging, controller: UIViewController, container: DependencyContaining) {
        self.itemsToDeleteManager = itemsToDeleteManager
        self.controller = controller
        self.container = container
    }
}

extension ProxiesTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let container = container, let proxy = container.proxiesManager.proxies[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            itemsToDeleteManager?.itemsToDelete[proxy.key] = proxy
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            controller?.showProxyController(proxy: proxy, container: container)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard
            tableView.isEditing,
            let proxy = container?.proxiesManager.proxies[safe: indexPath.row] else {
                return
        }
        itemsToDeleteManager?.itemsToDelete.removeValue(forKey: proxy.key)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
