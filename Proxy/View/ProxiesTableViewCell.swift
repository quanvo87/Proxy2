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
        convoCountLabel.text = proxy.convoCount.asLabel
        iconImageView.image = nil
        nameLabel.text = proxy.name
        newProxyBadgeImageView.image = nil
        newProxyBadgeImageView.isHidden = true
        nicknameLabel.text = proxy.nickname
        unreadLabel.text = nil // TODO: delete

        UIImage.makeImage(named: proxy.icon) { (image) in
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }

        if proxy.dateCreated.isNewProxyDate {
            UIImage.makeImage(named: "newProxyBadge") { (image) in
                DispatchQueue.main.async {
                    self.contentView.bringSubview(toFront: self.newProxyBadgeImageView)
                    self.newProxyBadgeImageView.image = image
                    self.newProxyBadgeImageView.isHidden = false
                }
            }
        }
    }
}
