import UIKit

class ProxiesTableViewDelegate: NSObject {
    private weak var controller: UITableViewController?
    private weak var itemsToDeleteManager: ItemsToDeleteManaging?
    private weak var proxiesManager: ProxiesManaging?

    func load(controller: UITableViewController, itemsToDeleteManager: ItemsToDeleteManaging, proxiesManager: ProxiesManaging) {
        self.controller = controller
        self.itemsToDeleteManager = itemsToDeleteManager
        self.proxiesManager = proxiesManager
        controller.tableView.delegate = self
    }
}

extension ProxiesTableViewDelegate: UITableViewDelegate {
    var proxies: [Proxy] {
        return proxiesManager?.proxies ?? []
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = proxies[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            itemsToDeleteManager?.itemsToDelete[proxy.key] = proxy
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            guard let proxyVC = controller?.storyboard?.instantiateViewController(withIdentifier: Identifier.proxyTableViewController) as? ProxyTableViewController else { return }
//            proxyVC.proxy = proxy
            controller?.navigationController?.pushViewController(proxyVC, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard
            tableView.isEditing,
            let proxy = proxies[safe: indexPath.row] else {
                return
        }
        itemsToDeleteManager?.itemsToDelete.removeValue(forKey: proxy.key)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
