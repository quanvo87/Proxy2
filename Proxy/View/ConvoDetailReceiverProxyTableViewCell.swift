import UIKit

class ConvoDetailReceiverProxyTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameButton: UIButton!

    func load(_ convo: Convo) {
        selectionStyle = .none

        iconImageView.image = nil
        nameLabel.text = convo.receiverProxyName
        nicknameButton.setTitle(convo.receiverNickname == "" ? "Enter A Nickname" : convo.receiverNickname, for: .normal)

        UIImage.make(named: convo.receiverIcon) { (image) in
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }
    }
}
