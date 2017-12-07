import UIKit

class ConvosTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var lastMessageLabel: UILabel!
    @IBOutlet weak var timestampLabel: UILabel!
    @IBOutlet weak var unreadLabel: UILabel!    // delete

    func load(_ convo: Convo) {
        iconImageView.image = nil
        titleLabel.attributedText = DBConvo.makeConvoTitle(convo)
        lastMessageLabel.text = convo.lastMessage
        timestampLabel.text = convo.timestamp.asTimeAgo
        unreadLabel.text = nil // TODO: delete
        UIImage.makeImage(named: convo.receiverIcon) { (image) in
            if let image = image {
                DispatchQueue.main.async {
                    self.iconImageView.image = image
                }
            }
        }
    }
}
