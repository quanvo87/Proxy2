import UIKit

class IconPickerCollectionViewDelegate: NSObject {
    private let iconNames: [String]
    private let proxy: Proxy
    private weak var controller: UIViewController?

    init(iconNames: [String], proxy: Proxy, controller: UIViewController?) {
        self.iconNames = iconNames
        self.proxy = proxy
        self.controller = controller
    }
}

extension IconPickerCollectionViewDelegate: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let iconName = iconNames[safe: indexPath.row] else {
            return
        }
        collectionView.cellForItem(at: indexPath)?.backgroundColor = UIColor.blue
        DB.setIcon(to: iconName, for: proxy) { _ in }
        controller?.dismiss(animated: true)
    }
}
