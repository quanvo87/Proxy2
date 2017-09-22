import UIKit

class ProxiesTableViewDelegate: NSObject {
    private weak var controller: ProxiesTableViewController?

    init(_ controller: ProxiesTableViewController) {
        super.init()
        controller.tableView.delegate = self
        self.controller = controller
    }
}

extension ProxiesTableViewDelegate: UITableViewDelegate {
    var proxies: [Proxy] {
        return controller?.proxies ?? []
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = proxies[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            controller?.set(proxy, forKey: proxy.key)
//            controller?.itemsToDelete[proxy.key] = proxy
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            goToProxyInfoVC(proxy)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard
            tableView.isEditing,
            let proxy = proxies[safe: indexPath.row] else {
                return
        }
        controller?.remove(atKey: proxy.key)
//        controller?.itemsToDelete.removeValue(forKey: proxy.key)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}

private extension ProxiesTableViewDelegate {
    func goToProxyInfoVC(_ proxy: Proxy) {
        guard let proxyVC = controller?.storyboard?.instantiateViewController(withIdentifier: Identifier.proxyTableViewController) as? ProxyTableViewController else { return }
        proxyVC.proxy = proxy
        controller?.navigationController?.pushViewController(proxyVC, animated: true)
    }
}
