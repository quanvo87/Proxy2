import UIKit

class IconPickerCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconNameLabel: UILabel!

    func load(_ icon: String) {
        iconNameLabel.text = icon
        iconImageView.image = nil
        UIImage.make(name: icon) { (image) in
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }
        layer.cornerRadius = 5
    }
}
