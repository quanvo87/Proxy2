//
//  MessagesTableViewDataSource.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

class MessagesTableViewDataSource: NSObject, UITableViewDataSource {
    weak var tableViewController: MessagesTableViewController?
    let convosManager = ConvosManager()

    init(_ tableViewController: MessagesTableViewController) {
        super.init()
        self.tableViewController = tableViewController
        convosManager.dataSource = self
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convosManager.convos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ConvoCell, for: indexPath as IndexPath) as! ConvoCell
        let convo = convosManager.convos[indexPath.row]

        cell.iconImageView.image = nil
        IconManager.shared.setIcon(convo.icon + ".png", forImageView: cell.iconImageView) // TODO: - set the ".png" somewhere else

        cell.titleLabel.attributedText = API.sharedInstance.getConvoTitle(receiverNickname: convo.receiverNickname,
                                                                          receiverName: convo.receiverProxyName,
                                                                          senderNickname: convo.senderNickname,
                                                                          senderName: convo.senderProxyName)
        cell.lastMessageLabel.text = convo.message
        cell.timestampLabel.text = convo.timestamp.toTimeAgo()
        cell.unreadLabel.text = convo.unread.toNumberLabel()

        return cell
    }
}
