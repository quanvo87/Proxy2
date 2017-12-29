import UIKit

class ProxiesTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var unreadMessagesIndicatorImageView: UIImageView!

    func load(proxy: Proxy, accessoryType: UITableViewCellAccessoryType) {
        self.accessoryType = accessoryType

        nameLabel.text = proxy.name
        nicknameLabel.text = proxy.nickname

        iconImageView.image = nil
        UIImage.make(name: proxy.icon) { (image) in
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }

        unreadMessagesIndicatorImageView.image = nil
        if proxy.hasUnreadMessage {
            unreadMessagesIndicatorImageView.image = UIImage.makeCircle(diameter: unreadMessagesIndicatorImageView.frame.width)
        }
    }
}
