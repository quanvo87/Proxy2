//
//  MessagesTableViewDataSource.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

class MessagesTableViewDataSource: NSObject, UITableViewDataSource {
    weak var tableViewController: MessagesTableViewController?
    lazy var convoManager: ConvoManager = {
        let convoManager = ConvoManager()
        convoManager.dataSource = self
        return convoManager
    }()

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convoManager.convos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ConvoCell, for: indexPath as IndexPath) as! ConvoCell
        let convo = convoManager.convos[indexPath.row]

        cell.iconImageView.image = nil
        cell.iconImageView.kf.indicatorType = .activity
//        api.getURL(forIconName: convo.icon) { (url) in
//            cell.iconImageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: nil)
//        }
//
//        cell.titleLabel.attributedText = api.getConvoTitle(receiverNickname: convo.receiverNickname, receiverName: convo.receiverProxyName, senderNickname: convo.senderNickname, senderName: convo.senderProxyName)
        cell.lastMessageLabel.text = convo.message
        cell.timestampLabel.text = convo.timestamp.toTimeAgo()
        cell.unreadLabel.text = convo.unread.toNumberLabel()

        return cell
    }
}
