import UIKit

class NewMessageMakerSenderTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    func load(_ proxy: Proxy?) {
        if let proxy = proxy {
            nameLabel.attributedText = proxy.label
            iconImageView.image = Image.make(proxy.icon)
        } else {
            nameLabel.text = "Pick Your Sender"
        }
        nameLabel.textColor = Color.iOSBlue
    }
}
