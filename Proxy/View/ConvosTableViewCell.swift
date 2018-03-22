import UIKit

class ConvosTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var unreadMessagesIndicatorImageView: UIImageView!

    func load(_ convo: Convo) {
        iconImageView.image = nil
        iconImageView.image = UIImage(named: convo.receiverIcon)
        lastMessageLabel.text = convo.lastMessage
        timestampLabel.text = convo.timestamp.asTimeAgo
        titleLabel.attributedText = convo.label
        unreadMessagesIndicatorImageView.image = nil
        if convo.hasUnreadMessage {
            unreadMessagesIndicatorImageView.image = Image.makeCircle(
                diameter: unreadMessagesIndicatorImageView.frame.width
            )
        }
    }
}
