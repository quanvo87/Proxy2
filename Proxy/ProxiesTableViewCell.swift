import UIKit

class ProxiesTableViewCell: UITableViewCell {
    @IBOutlet weak var convoCountLabel: UILabel!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var newProxyBadgeImageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!    // TODO: delete

    func configure(_ proxy: Proxy) {
        accessoryType = .none
        convoCountLabel.text = proxy.convoCount.asLabel
        iconImageView.image = nil
        nameLabel.text = proxy.name
        newProxyBadgeImageView.image = nil
        newProxyBadgeImageView.isHidden = true
        nicknameLabel.text = proxy.nickname
        unreadLabel.text = nil // TODO: delete

        DBProxy.getImageForIcon(proxy.icon) { (result) in
            guard let (icon, image) = result else { return }
            DispatchQueue.main.async {
                guard icon == proxy.icon else { return }
                self.iconImageView.image = image
            }
        }

        if proxy.dateCreated.isNewProxyDate {
            DBProxy.makeNewProxyBadge { (image) in
                guard let image = image else { return }
                DispatchQueue.main.async {
                    guard proxy.dateCreated.isNewProxyDate else { return }
                    self.contentView.bringSubview(toFront: self.newProxyBadgeImageView)
                    self.newProxyBadgeImageView.image = image
                    self.newProxyBadgeImageView.isHidden = false
                }
            }
        }
    }
}
