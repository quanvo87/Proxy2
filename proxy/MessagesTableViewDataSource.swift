//
//  MessagesTableViewDataSource.swift
//  proxy
//
//  Created by Quan Vo on 6/8/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

class MessagesTableViewDataSource: NSObject, UITableViewDataSource {
    weak var tableViewController: MessagesTableViewController?
    lazy var convosObserver = ConvosObserver()

    override init() {}

    func load(_ tableViewController: MessagesTableViewController) {
        self.tableViewController = tableViewController
        convosObserver.observe(self)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return convosObserver.convos.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.ConvoCell, for: indexPath as IndexPath) as! ConvoCell
        let convo = convosObserver.convos[indexPath.row]

        cell.iconImageView.image = nil

        // TODO: - set the ".png" somewhere else
        DBIcon.getImageForIcon(convo.icon + ".png" as AnyObject, tag: cell.tag) { (image, tag) in
            guard tag == cell.tag else { return }
            guard let image = image else {
                return
            }
            DispatchQueue.main.async {
                cell.iconImageView.image = image
            }
        }
        cell.titleLabel.attributedText = API.sharedInstance.getConvoTitle(receiverNickname: convo.receiverNickname,
                                                                          receiverName: convo.receiverProxyName,
                                                                          senderNickname: convo.senderNickname,
                                                                          senderName: convo.senderProxyName)
        cell.lastMessageLabel.text = convo.message
        cell.timestampLabel.text = convo.timestamp.asTimeAgo
        cell.unreadLabel.text = convo.unread.asLabel
        
        return cell
    }
}
