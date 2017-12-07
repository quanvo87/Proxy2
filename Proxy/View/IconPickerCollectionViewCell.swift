import UIKit

class IconPickerCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var iconNameLabel: UILabel!

    func load(_ icon: String) {
        iconImageView.image = nil
        iconNameLabel.text = icon
        layer.cornerRadius = 5
        UIImage.makeImage(named: icon) { (image) in
            guard let image = image else { return }
            DispatchQueue.main.async {
                self.iconImageView.image = image
            }
        }
    }
}
