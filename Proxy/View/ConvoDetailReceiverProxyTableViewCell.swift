import UIKit

class ConvoDetailReceiverProxyTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameButton: UIButton!

    func load(_ convo: Convo) {
        selectionStyle = .none

        nameLabel.text = convo.receiverProxyName
        nicknameButton.setTitle(convo.receiverNickname == "" ? "Enter A Nickname" : convo.receiverNickname, for: .normal)

        iconImageView.image = nil
        UIImage.make(name: convo.receiverIcon) { [weak self] image in
            DispatchQueue.main.async {
                self?.iconImageView.image = image
            }
        }
    }
}
