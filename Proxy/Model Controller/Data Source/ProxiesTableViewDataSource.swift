import UIKit

class ProxiesTableViewDataSource: NSObject {
    private var accessoryType: UITableViewCellAccessoryType = .none
    private weak var manager: ProxiesManaging?

    func load(manager: ProxiesManaging, accessoryType: UITableViewCellAccessoryType) {
        self.manager = manager
        self.accessoryType = accessoryType
    }
}

extension ProxiesTableViewDataSource: UITableViewDataSource {
    var proxies: [Proxy] {
        return manager?.proxies ?? []
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell) as? ProxiesTableViewCell,
            let proxy = proxies[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell, for: indexPath)
        }
        cell.load(proxy: proxy, accessoryType: accessoryType)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
}
