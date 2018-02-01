import UIKit

class SenderProxyTableViewCell: UITableViewCell {
    @IBOutlet weak var changeIconButton: UIButton!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameButton: UIButton!

    func load(_ proxy: Proxy) {
        nameLabel.text = proxy.name
        nicknameButton.setTitle(proxy.nickname == "" ? "Enter A Nickname" : proxy.nickname, for: .normal)
        iconImageView.image = nil
        UIImage.make(name: proxy.icon) { [weak self] image in
            DispatchQueue.main.async {
                self?.iconImageView.image = image
            }
        }
    }
}
