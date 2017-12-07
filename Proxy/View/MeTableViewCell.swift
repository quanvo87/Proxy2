import UIKit

class MeTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!

    func load(icon: String, title: String?, subtitle: String?) {
        iconImageView.image = nil
        titleLabel.text = title
        subtitleLabel.text = subtitle
        UIImage.makeImage(named: icon) { (image) in
            guard let image = image else { return }
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }
    }
}
