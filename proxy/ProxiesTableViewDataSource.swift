class ProxiesTableViewDataSource: NSObject, UITableViewDataSource {
    let proxiesObserver = ProxiesObserver()
    var tableview: UITableView?

    init(_ tableview: UITableView) {
        self.tableview = tableview
        proxiesObserver.observeProxies(tableview)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxiesObserver.getProxies().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.ProxyCell, for: indexPath as IndexPath) as? ProxyCell else {
            return UITableViewCell()
        }

        let proxy = proxiesObserver.getProxies()[indexPath.row]

        cell.accessoryType = .none
        cell.convoCountLabel.text = proxy.convoCount.asLabel
        cell.iconImageView.image = nil
        cell.nameLabel.text = proxy.name
        cell.newImageView.isHidden = true
        cell.nicknameLabel.text = proxy.nickname
        cell.unreadLabel.text = proxy.unreadCount.asLabel

        DBStorage.getImageForIcon(proxy.icon, tag: cell.tag) { (result) in
            guard
                let (image, tag) = result,
                tag == cell.tag else {
                    return
            }
            DispatchQueue.main.async {
                cell.iconImageView.image = image
            }
        }

        let secondsAgo = -Date(timeIntervalSince1970: proxy.dateCreated).timeIntervalSinceNow
        if secondsAgo < 60 * Settings.NewProxyIndicatorDuration {
            cell.contentView.bringSubview(toFront: cell.newImageView)
            cell.newImageView.isHidden = false
        }

        return cell
    }
}
