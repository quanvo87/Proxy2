import UIKit

class ProxiesTableViewDataSource: NSObject {
    private var accessoryType: UITableViewCellAccessoryType = .none
    private weak var manager: ProxiesManaging?

    func load(accessoryType: UITableViewCellAccessoryType, manager: ProxiesManaging) {
        self.accessoryType = accessoryType
        self.manager = manager
    }
}

extension ProxiesTableViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell) as? ProxiesTableViewCell,
            let proxy = manager?.proxies[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell, for: indexPath)
        }
        cell.load(proxy: proxy, accessoryType: accessoryType)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return manager?.proxies.count ?? 0
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if manager?.proxies.isEmpty ?? false {
            return "Tap the bouncing button to make a new Proxy 👶🏾."
        } else {
            return nil
        }
    }
}
