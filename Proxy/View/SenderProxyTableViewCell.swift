import UIKit

class SenderProxyTableViewCell: UITableViewCell {
    @IBOutlet weak var changeIconButton: UIButton!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameButton: UIButton!

    func load(_ proxy: Proxy) {
        iconImageView.image = Image.make(proxy.icon)
        nameLabel.text = proxy.name
        nicknameButton.setTitle(proxy.nickname == "" ? "Enter A Nickname" : proxy.nickname, for: .normal)
    }
}
