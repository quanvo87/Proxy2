import UIKit

class MakeNewMessageSenderTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!

    func load(_ proxy: Proxy?) {
        if let proxy = proxy {
            nameLabel.text = proxy.name
            iconImageView.image = UIImage(named: proxy.icon)
        } else {
            nameLabel.text = "Pick Your Sender"
        }
        nameLabel.textColor = Color.blue
    }
}
