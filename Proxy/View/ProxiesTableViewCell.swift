import UIKit

class ProxiesTableViewCell: UITableViewCell {
    @IBOutlet weak var convoCountLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var newProxyBadgeImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!    // TODO: delete
    
    func load(proxy: Proxy, accessoryType: UITableViewCellAccessoryType) {
        self.accessoryType = accessoryType
        
        iconImageView.image = nil
        newProxyBadgeImageView.image = nil
        newProxyBadgeImageView.isHidden = true
        nameLabel.text = proxy.name
        nicknameLabel.text = proxy.nickname
        convoCountLabel.text = proxy.convoCount.asLabel
        unreadLabel.text = nil // TODO: delete

        UIImage.make(named: proxy.icon) { (image) in
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }

        if proxy.dateCreated.isNewProxyDate {
            UIImage.make(named: "newProxyBadge") { (image) in
                guard let image = image else {
                    return
                }
                DispatchQueue.main.async {
                    self.contentView.bringSubview(toFront: self.newProxyBadgeImageView)
                    self.newProxyBadgeImageView.image = image
                    self.newProxyBadgeImageView.isHidden = false
                }
            }
        }
    }
}
