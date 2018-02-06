import UIKit

class IconPickerCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconNameLabel: UILabel!

    func load(_ icon: String) {
        iconImageView.image = nil
        iconImageView.image = UIImage(named: icon)
        iconNameLabel.text = icon
        layer.cornerRadius = 5
    }
}
