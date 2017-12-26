import UIKit

class ProxiesTableViewCell: UITableViewCell {
    @IBOutlet weak var convoCountLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var newProxyBadgeImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var unreadMessagesIndicatorImageView: UIImageView!

    func load(proxy: Proxy, accessoryType: UITableViewCellAccessoryType) {
        self.accessoryType = accessoryType

        nameLabel.text = proxy.name
        nicknameLabel.text = proxy.nickname
        convoCountLabel.text = proxy.convoCount.asLabel

        iconImageView.image = nil
        UIImage.make(name: proxy.icon) { (image) in
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }

        newProxyBadgeImageView.image = nil
        if proxy.dateCreated.isNewProxyDate {
            UIImage.make(name: "newProxyBadge") { (image) in
                DispatchQueue.main.async {
                    self.newProxyBadgeImageView.image = image
                }
            }
        }

        unreadMessagesIndicatorImageView.image = nil
        if proxy.hasUnreadMessage {
            unreadMessagesIndicatorImageView.image = UIImage.makeCircle(diameter: unreadMessagesIndicatorImageView.frame.width)
        }
    }
}
