import UIKit

class ProxiesTableViewDataSource: NSObject {
    private var id: Int { return ObjectIdentifier(self).hashValue }
    private weak var proxiesObserver: ProxiesObserver?
    private weak var tableView: UITableView?

    init(_ tableView: UITableView) {
        super.init()
        proxiesObserver = (UIApplication.shared.delegate as? AppDelegate)?.proxiesObserver
        self.tableView = tableView
        tableView.dataSource = self
    }

    func observe() {
        guard let tableView = tableView else { return }
        proxiesObserver?.observe(tableView)
    }

    func stopObserving() {
        proxiesObserver?.stopObserving()
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
