class ProxiesTableViewDataSource: NSObject, UITableViewDataSource {
    private let proxiesObserver = ProxiesObserver()

    var proxies: [Proxy] {
        return proxiesObserver.proxies
    }

    override init() {}

    func observe(_ tableView: UITableView) {
        proxiesObserver.observe(tableView)
    }

    func stopObserving() {
        proxiesObserver.stopObserving()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.ProxyCell, for: indexPath) as? ProxyCell,
            let proxy = proxies[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.ProxyCell, for: indexPath)
        }

        cell.accessoryType = .none
        cell.convoCountLabel.text = proxy.convoCount.asLabel
        cell.iconImageView.image = nil
        cell.nameLabel.text = proxy.name
        cell.newImageView.image = nil
        cell.newImageView.isHidden = true
        cell.nicknameLabel.text = proxy.nickname
        cell.unreadLabel.text = nil // TODO: delete

        DBProxy.getImageForIcon(proxy.icon, tag: cell.tag) { (result) in
            guard let (image, tag) = result else { return }
            DispatchQueue.main.async {
                guard tag == cell.tag else { return }
                cell.iconImageView.image = image
            }
        }

        // TODO: add tag check
        if proxy.dateCreated.isNewProxyDate {
            DBProxy.makeNewProxyBadge { (image) in
                guard let image = image else { return }
                DispatchQueue.main.async {
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
