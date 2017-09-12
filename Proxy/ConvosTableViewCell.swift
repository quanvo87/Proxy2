import UIKit

class ConvosTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!    // delete

    func configure(_ convo: Convo) {
        iconImageView.image = nil
        lastMessageLabel.text = convo.lastMessage
        timestampLabel.text = convo.timestamp.asTimeAgo
        titleLabel.attributedText = DBConvo.makeConvoTitle(convo)
        unreadLabel.text = nil // TODO: delete

        DBProxy.getImageForIcon(convo.receiverIcon) { (image) in
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }
    }
}
