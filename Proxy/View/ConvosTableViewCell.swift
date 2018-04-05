import UIKit

class ConvosTableViewCell: UITableViewCell {
    @IBOutlet weak var blockedIndicatorImageView: UIImageView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var unreadMessagesIndicatorImageView: UIImageView!

    func load(_ convo: Convo) {
        blockedIndicatorImageView.image = convo.receiverIsBlocked ? UIImage(named: "blockUser") : nil
        iconImageView.image = Image.make(convo.receiverIcon)
        lastMessageLabel.text = convo.lastMessage
        timestampLabel.text = convo.timestamp.asTimeAgo
        titleLabel.attributedText = convo.label
        unreadMessagesIndicatorImageView.image = convo.hasUnreadMessage ?
            Image.makeCircle(diameter: unreadMessagesIndicatorImageView.frame.width) : nil
    }
}
