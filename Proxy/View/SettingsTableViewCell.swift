import UIKit

class SettingsTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    func load(icon: String, title: String, subtitle: String? = nil) {
        iconImageView.image = UIImage(named: icon)
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
}
