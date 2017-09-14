import UIKit

class ProxiesTableViewDelegate: NSObject {
    private weak var proxiesObserver: ProxiesObserver?
    private weak var tableViewController: ProxiesTableViewController?

    init(_ tableViewController: ProxiesTableViewController) {
        super.init()
        self.proxiesObserver = (UIApplication.shared.delegate as? AppDelegate)?.proxiesObserver
        self.tableViewController = tableViewController
        tableViewController.tableView.delegate = self
    }
}

extension ProxiesTableViewDelegate: UITableViewDelegate {
    var proxies: [Proxy] {
        return proxiesObserver?.proxies ?? []
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = proxies[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            tableViewController?.itemsToDelete[proxy.key] = proxy
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
        tableViewController?.itemsToDelete.removeValue(forKey: proxy.key)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}

extension ProxiesTableViewDelegate {
    func goToProxyInfoVC(_ proxy: Proxy) {
        guard let proxyVC = tableViewController?.storyboard?.instantiateViewController(withIdentifier: Identifier.proxyTableViewController) as? ProxyTableViewController else { return }
        proxyVC.proxy = proxy
        tableViewController?.navigationController?.pushViewController(proxyVC, animated: true)
    }
}
