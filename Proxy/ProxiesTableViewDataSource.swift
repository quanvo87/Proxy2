import UIKit

class ProxiesTableViewDataSource: NSObject {
    private(set) weak var proxiesObserver: ProxiesObserver?

    var id: Int {
        return ObjectIdentifier(self).hashValue
    }

    init(_ tableView: UITableView) {
        super.init()

        proxiesObserver = (UIApplication.shared.delegate as? AppDelegate)?.proxiesObserver
        proxiesObserver?.addTableView(tableView, forKey: id)

        tableView.dataSource = self
    }

    deinit {
        proxiesObserver?.removeTableView(forKey: id)
    }
}

extension ProxiesTableViewDataSource: UITableViewDataSource {
    var proxies: [Proxy] {
        return proxiesObserver?.proxies ?? []
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
