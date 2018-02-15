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
        titleLabel.attributedText = NSAttributedString.makeConvoTitle(convo)
        unreadMessagesIndicatorImageView.image = nil
        if convo.hasUnreadMessage {
            unreadMessagesIndicatorImageView.image = Image.makeCircle(diameter: unreadMessagesIndicatorImageView.frame.width)
        }
    }
}

// https://gist.github.com/minorbug/468790060810e0d29545
private extension Double {
    var asTimeAgo: String {
        let calendar = NSCalendar.current
        let unitFlags: Set<Calendar.Component> = [.minute, .hour, .day, .weekOfYear, .month, .year, .second]
        let this = Date(timeIntervalSince1970: self)
        let now = Date()
        let earliest = now < this ? now : this
        let latest = earliest == now ? this : now
        let components = calendar.dateComponents(unitFlags, from: earliest, to: latest)

        if components.year! > 0 {
            return "\(components.year!)y"
        } else if components.month! > 0 {
            return "\(components.month!)mo"
        } else if components.weekOfYear! > 0 {
            return "\(components.weekOfYear!)w"
        } else if components.day! > 0 {
            return "\(components.day!)d"
        } else if components.hour! > 0 {
            return "\(components.hour!)h"
        } else if components.minute! > 0 {
            return "\(components.minute!)m"
        } else if components.second! >= 3 {
            return "\(components.second!)s"
        } else {
            return "Just now"
        }
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
