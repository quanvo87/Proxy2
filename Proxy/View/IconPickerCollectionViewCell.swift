import UIKit

class IconPickerCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconNameLabel: UILabel!

    func load(_ icon: String) {
        iconImageView.image = Image.make(icon)
        iconNameLabel.text = icon
        layer.cornerRadius = 5
    }
}
