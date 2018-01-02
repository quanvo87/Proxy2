import UIKit

class ProxiesTableViewDataSource: NSObject {
    private var accessoryType: UITableViewCellAccessoryType = .none
    private var container: DependencyContaining = DependencyContainer.container

    func load(accessoryType: UITableViewCellAccessoryType, container: DependencyContaining) {
        self.accessoryType = accessoryType
        self.container = container
    }
}

extension ProxiesTableViewDataSource: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell) as? ProxiesTableViewCell,
            let proxy = container.proxiesManager.proxies[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell, for: indexPath)
        }
        cell.load(proxy: proxy, accessoryType: accessoryType)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return container.proxiesManager.proxies.count
    }
}
