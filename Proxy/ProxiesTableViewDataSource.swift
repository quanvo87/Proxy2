import UIKit

class ProxiesTableViewDataSource: NSObject, UITableViewDataSource {
    private let proxiesObserver = ProxiesObserver()

    var proxies: [Proxy] {
        return proxiesObserver.proxies
    }

    override init() {}

    func observe(_ tableView: UITableView) {
        proxiesObserver.observe(tableView)
        tableView.dataSource = self
    }

    func stopObserving() {
        proxiesObserver.stopObserving()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell) as? ProxiesTableViewCell,
            let proxy = proxies[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.proxiesTableViewCell, for: indexPath)
        }

        cell.accessoryType = .none
        cell.convoCountLabel.text = proxy.convoCount.asLabel
        cell.iconImageView.image = nil
        cell.nameLabel.text = proxy.name
        cell.newImageView.image = nil
        cell.newImageView.isHidden = true
        cell.nicknameLabel.text = proxy.nickname
        cell.unreadLabel.text = nil // TODO: delete

        DBProxy.getImageForIcon(proxy.icon) { (result) in
            guard let (icon, image) = result else { return }
            DispatchQueue.main.async {
                guard icon == proxy.icon else { return }
                cell.iconImageView.image = image
            }
        }

        if proxy.dateCreated.isNewProxyDate {
            DBProxy.makeNewProxyBadge { (image) in
                guard let image = image else { return }
                DispatchQueue.main.async {
                    guard proxy.dateCreated.isNewProxyDate else { return }
                    cell.contentView.bringSubview(toFront: cell.newImageView)
                    cell.newImageView.image = image
                    cell.newImageView.isHidden = false
                }
            }
        }

        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
}
