import UIKit

class ProxiesTableViewDataSource: NSObject {
    private weak var proxiesObserver: ProxiesObserver?

    var id: Int {
        return ObjectIdentifier(self).hashValue
    }

    init(_ tableView: UITableView) {
        super.init()

        tableView.dataSource = self

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.proxiesObserver = appDelegate.proxiesObserver
            self.proxiesObserver?.addTableView(tableView, forKey: id)
        }
    }

    deinit {
        proxiesObserver?.removeTableView(forKey: id)
    }

    func observe() {
        proxiesObserver?.observe()
    }

    func stopObserving() {
        proxiesObserver?.stopObserving()
    }
}

extension ProxiesTableViewDataSource: UITableViewDataSource {
    var proxies: [Proxy] {
        if let proxies = proxiesObserver?.proxies {
            return proxies
        }
        return []
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell) as? ProxiesTableViewCell,
            let proxy = proxies[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell, for: indexPath)
        }

        cell.configure(proxy)

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
}
