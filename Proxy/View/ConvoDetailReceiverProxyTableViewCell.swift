import UIKit

class ConvoDetailReceiverProxyTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameButton: UIButton!

    func load(_ convo: Convo) {
        selectionStyle = .none
        iconImageView.image = nil
        iconImageView.image = UIImage(named: convo.receiverIcon)
        nameLabel.text = convo.receiverProxyName
        nicknameButton.setTitle(convo.receiverNickname == "" ? "Enter A Nickname" : convo.receiverNickname, for: .normal)
    }
}
