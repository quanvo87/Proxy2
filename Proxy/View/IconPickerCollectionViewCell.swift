import UIKit

class IconPickerCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconNameLabel: UILabel!

    func load(_ icon: String) {
        layer.cornerRadius = 5
        iconImageView.image = nil
        iconNameLabel.text = icon
        UIImage.makeImage(named: icon) { (image) in
            if let image = image {
                DispatchQueue.main.async {
                    self.iconImageView.image = image
                }
            }
        }
    }
}
