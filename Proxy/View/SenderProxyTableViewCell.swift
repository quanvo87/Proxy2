import UIKit

class SenderProxyTableViewCell: UITableViewCell {
    @IBOutlet weak var changeIconButton: UIButton!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameButton: UIButton!

    func load(_ proxy: Proxy) {
        iconImageView.image = nil
        nameLabel.text = proxy.name
        nicknameButton.setTitle(proxy.nickname == "" ? "Enter A Nickname" : proxy.nickname, for: .normal)
        selectionStyle = .none
        UIImage.makeImage(named: proxy.icon) { (image) in
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }
    }
}
