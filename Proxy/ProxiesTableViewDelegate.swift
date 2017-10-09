import UIKit

class ProxiesTableViewDelegate: NSObject {
    weak var controller: UIViewController?
    weak var itemsToDeleteManager: ItemsToDeleteManaging?
    weak var proxiesManager: ProxiesManaging?
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
            proxyVC.proxy = proxy
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
