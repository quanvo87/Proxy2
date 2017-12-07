import UIKit

class ProxiesTableViewDataSource: NSObject {
    private var showDisclosureIndicator = false
    private weak var manager: ProxiesManaging?

    func load(manager: ProxiesManaging, showDisclosureIndicator: Bool) {
        self.manager = manager
        self.showDisclosureIndicator = showDisclosureIndicator
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
        cell.load(proxy: proxy, showDisclosureIndicator: showDisclosureIndicator)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
}
