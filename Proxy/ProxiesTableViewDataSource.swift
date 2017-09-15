import UIKit

class ProxiesTableViewDataSource: NSObject {
    private weak var controller: ProxiesObserving?

    init(_ controller: ProxiesObserving) {
        super.init()
        controller.tableView.dataSource = self
        self.controller = controller
    }
}

extension ProxiesTableViewDataSource: UITableViewDataSource {
    var proxies: [Proxy] {
        return controller?.proxies ?? []
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
