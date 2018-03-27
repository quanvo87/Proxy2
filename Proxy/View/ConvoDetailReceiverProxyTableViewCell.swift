import UIKit

class ConvoDetailReceiverProxyTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameButton: UIButton!

    func load(convo: Convo, isBlockingReceiver: Bool) {
        selectionStyle = .none
        iconImageView.image = nil
        iconImageView.image = UIImage(named: convo.receiverIcon)
        nameLabel.text = isBlockingReceiver ? convo.receiverProxyName + " 🚫" : convo.receiverProxyName
        nicknameButton.setTitle(
            convo.receiverNickname == "" ? "Enter A Nickname" : convo.receiverNickname, for: .normal
        )
    }
}
