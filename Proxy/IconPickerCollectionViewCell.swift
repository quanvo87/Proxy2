import UIKit

class IconPickerCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconNameLabel: UILabel!

    func configure(_ icon: String) {
        iconImageView.image = nil
        iconNameLabel.text = icon
        layer.cornerRadius = 5
        DBProxy.getImageForIcon(icon) { (image) in
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }
    }
}
