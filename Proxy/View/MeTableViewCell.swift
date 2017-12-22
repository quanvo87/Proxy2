import UIKit

class MeTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    func load(icon: String, title: String?, subtitle: String?) {
        iconImageView.image = nil
        titleLabel.text = title
        subtitleLabel.text = subtitle

        UIImage.make(named: icon) { (image) in
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }
    }
}
