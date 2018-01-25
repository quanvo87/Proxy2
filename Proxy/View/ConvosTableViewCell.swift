import UIKit

class ConvosTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var unreadMessagesIndicatorImageView: UIImageView!

    func load(_ convo: Convo) {
        titleLabel.attributedText = NSAttributedString.makeConvoTitle(convo)
        lastMessageLabel.text = convo.lastMessage
        timestampLabel.text = convo.timestamp.asTimeAgo

        iconImageView.image = nil
        UIImage.make(name: convo.receiverIcon) { (image) in
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }

        unreadMessagesIndicatorImageView.image = nil
        if convo.hasUnreadMessage {
            unreadMessagesIndicatorImageView.image = UIImage.makeCircle(diameter: unreadMessagesIndicatorImageView.frame.width)
        }
    }
}

private extension Double {
    var asTimeAgo: String {
        return NSDate(timeIntervalSince1970: self).formattedAsTimeAgo()
    }
}

extension NSAttributedString {
    static func makeConvoTitle(_ convo: Convo) -> NSAttributedString {
        let grayAttribute = [NSAttributedStringKey.foregroundColor: UIColor.gray]
        let receiver = NSMutableAttributedString(string: (convo.receiverNickname == "" ? convo.receiverProxyName : convo.receiverNickname) + ", ")
        let sender = NSMutableAttributedString(string: convo.senderNickname == "" ? convo.senderProxyName : convo.senderNickname,
                                               attributes: grayAttribute)
        receiver.append(sender)
        return receiver
    }
}
