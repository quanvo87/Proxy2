import UIKit

class ProxiesTableViewCell: UITableViewCell {
    @IBOutlet weak var convoCountLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var newProxyBadgeImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!    // TODO: delete
    
    func load(proxy: Proxy, showDisclosureIndicator: Bool) {
        accessoryType = showDisclosureIndicator ? .disclosureIndicator : .none
        
        iconImageView.image = nil
        newProxyBadgeImageView.image = nil
        newProxyBadgeImageView.isHidden = true
        nameLabel.text = proxy.name
        nicknameLabel.text = proxy.nickname
        convoCountLabel.text = proxy.convoCount.asLabel
        unreadLabel.text = nil // TODO: delete

        UIImage.makeImage(named: proxy.icon) { (image) in
            if let image = image {
                DispatchQueue.main.async {
                    self.iconImageView.image = image
                }
            }
        }

        if proxy.dateCreated.isNewProxyDate {
            UIImage.makeImage(named: "newProxyBadge") { (image) in
                if let image = image {
                    DispatchQueue.main.async {
                        self.contentView.bringSubview(toFront: self.newProxyBadgeImageView)
                        self.newProxyBadgeImageView.image = image
                        self.newProxyBadgeImageView.isHidden = false
                    }
                }
            }
        }
    }
}
