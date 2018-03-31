import UIKit

class ConvoDetailReceiverProxyTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameButton: UIButton!

    func load(_ convo: Convo) {
        selectionStyle = .none
        iconImageView.image = Image.make(convo.receiverIcon)
        nameLabel.text = convo.receiverIsBlocked ? convo.receiverProxyName + " 🚫" : convo.receiverProxyName
        nicknameButton.setTitle(
            convo.receiverNickname == "" ? "Enter A Nickname" : convo.receiverNickname, for: .normal
        )
    }
}
