import UIKit

class IconPickerCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconNameLabel: UILabel!

    func load(_ icon: String) {
        layer.cornerRadius = 5

        iconNameLabel.text = icon

        iconImageView.image = nil
        UIImage.make(name: icon) { (image) in
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }
    }
}
