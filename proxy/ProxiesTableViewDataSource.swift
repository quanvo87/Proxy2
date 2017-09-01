class ProxiesTableViewDataSource: NSObject, UITableViewDataSource {
    let proxiesObserver = ProxiesObserver()

    override init() {}

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxiesObserver.getProxies().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.ProxyCell, for: indexPath) as? ProxyCell,
            let proxy = proxiesObserver.getProxies()[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.ProxyCell, for: indexPath)
        }

        cell.accessoryType = .none
        cell.convoCountLabel.text = proxy.convoCount.asLabel
        cell.iconImageView.image = nil
        cell.nameLabel.text = proxy.name
        cell.newImageView.isHidden = true
        cell.nicknameLabel.text = proxy.nickname
        cell.unreadLabel.text = proxy.unreadCount.asLabel

        DBProxy.getImageForIcon(proxy.icon, tag: cell.tag) { (result) in
            guard let (image, tag) = result, tag == cell.tag else {
                return
            }
            DispatchQueue.main.async {
                cell.iconImageView.image = image
            }
        }

        // TODO: Do on bg queue
        if proxy.dateCreated.isNewProxyDate {
            cell.contentView.bringSubview(toFront: cell.newImageView)
            cell.newImageView.image = UIImage(named: "New Proxy Badge")
            cell.newImageView.isHidden = false
        }

        return cell
    }
}
