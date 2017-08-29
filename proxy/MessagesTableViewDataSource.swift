class MessagesTableViewDataSource: NSObject, UITableViewDataSource {
    var tableView: UITableView?
    var convosObserver = ConvosObserver()

    override init() {}

    func load(_ tableView: UITableView) {
        self.tableView = tableView
        convosObserver.observeConvos(tableView)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convosObserver.getConvos().count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.ConvoCell, for: indexPath as IndexPath) as? ConvoCell else {
            return UITableViewCell()
        }

        let convo = convosObserver.getConvos()[indexPath.row]

        cell.iconImageView.image = nil
        cell.lastMessageLabel.text = convo.lastMessage
        cell.timestampLabel.text = convo.timestamp.asTimeAgo
        cell.titleLabel.attributedText = DBConvo.makeConvoTitle(receiverNickname: convo.receiverNickname,
                                                                receiverProxyName: convo.receiverProxyName,
                                                                senderNickname: convo.senderNickname,
                                                                senderProxyName: convo.senderProxyName)
        cell.unreadLabel.text = convo.unreadCount.asLabel

        DBStorage.getImageForIcon(convo.receiverIcon, tag: cell.tag) { (result) in
            guard
                let (image, tag) = result,
                tag == cell.tag else {
                    return
            }
            DispatchQueue.main.async {
                cell.iconImageView.image = image
            }
        }
        
        return cell
    }
}
