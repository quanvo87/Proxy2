import UIKit

class ProxiesTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var unreadMessagesIndicatorImageView: UIImageView!

    func load(proxy: Proxy, accessoryType: UITableViewCellAccessoryType) {
        self.accessoryType = accessoryType
        iconImageView.image = nil
        iconImageView.image = UIImage(named: proxy.icon)
        nameLabel.text = proxy.name
        nicknameLabel.text = proxy.nickname
        unreadMessagesIndicatorImageView.image = nil
        if proxy.hasUnreadMessage {
            unreadMessagesIndicatorImageView.image = UIImage.makeCircle(diameter: unreadMessagesIndicatorImageView.frame.width)
        }
    }
}
