class MessagesTableViewDataSource: NSObject, UITableViewDataSource {
    private let convosObserver = ConvosObserver()

    var convos: [Convo] {
        return convosObserver.convos
    }

    override init() {}

    func observe(_ tableView: UITableView) {
        convosObserver.observeConvos(forOwner: Shared.shared.uid, tableView: tableView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.ConvoCell, for: indexPath) as? ConvoCell,
            let convo = convos[safe: indexPath.row] else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.ConvoCell, for: indexPath)
        }

        cell.iconImageView.image = nil
        cell.lastMessageLabel.text = convo.lastMessage
        cell.timestampLabel.text = convo.timestamp.asTimeAgo
        cell.titleLabel.attributedText = DBConvo.makeConvoTitle(receiverNickname: convo.receiverNickname,
                                                                receiverProxyName: convo.receiverProxyName,
                                                                senderNickname: convo.senderNickname,
                                                                senderProxyName: convo.senderProxyName)
//        cell.unreadLabel.text = convo.unreadCount.asLabel

        DBProxy.getImageForIcon(convo.receiverIcon, tag: cell.tag) { (result) in
            guard let (image, tag) = result else { return }
            DispatchQueue.main.async {
                guard tag == cell.tag else { return }
                cell.imageView?.image = image
            }
        }
        
        return cell
    }
}
