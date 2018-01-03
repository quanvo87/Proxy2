import UIKit

class ProxiesTableViewDelegate: NSObject {
    private var container: DependencyContaining = DependencyContainer.container
    private weak var manager: ItemsToDeleteManaging?
    private weak var controller: UIViewController?

    func load(manager: ItemsToDeleteManaging, controller: UIViewController, container: DependencyContaining) {
        self.manager = manager
        self.controller = controller
        self.container = container
    }
}

extension ProxiesTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = container.proxiesManager.proxies[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            manager?.itemsToDelete[proxy.key] = proxy
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            controller?.showProxyController(proxy: proxy, container: container)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard
            tableView.isEditing,
            let proxy = container.proxiesManager.proxies[safe: indexPath.row] else {
                return
        }
        manager?.itemsToDelete.removeValue(forKey: proxy.key)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
