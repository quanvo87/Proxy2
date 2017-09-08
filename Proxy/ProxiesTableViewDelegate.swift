import UIKit

class ProxiesTableViewDelegate: NSObject {
    private weak var buttonManager: ButtonManager?
    private weak var proxiesObserver: ProxiesObserver?
    private weak var tableViewController: ProxiesTableViewController?

    init(buttonManager: ButtonManager, tableViewController: ProxiesTableViewController) {
        super.init()

        self.buttonManager = buttonManager
        self.tableViewController = tableViewController
        tableViewController.tableView.delegate = self

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.proxiesObserver = appDelegate.proxiesObserver
        }
    }
}

extension ProxiesTableViewDelegate: UITableViewDelegate {
    var proxies: [Proxy] {
        if let proxies = proxiesObserver?.proxies {
            return proxies
        }
        return []
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = proxies[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            buttonManager?.setItemToDelete(value: proxy, forKey: proxy.key)
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            goToProxyInfoVC(proxy)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard let proxy = proxies[safe: indexPath.row] else {
            return
        }
        buttonManager?.removeItemToDelete(forKey: proxy.key)
    }

    func goToProxyInfoVC(_ proxy: Proxy) {
        guard let proxyVC = tableViewController?.storyboard?.instantiateViewController(withIdentifier: Identifier.proxyTableViewController) as? ProxyTableViewController else { return }
        proxyVC.setProxy(proxy)
        tableViewController?.navigationController?.pushViewController(proxyVC, animated: true)
    }
}
