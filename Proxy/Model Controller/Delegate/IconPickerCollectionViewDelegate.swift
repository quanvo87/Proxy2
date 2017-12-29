import UIKit

class IconPickerCollectionViewDelegate: NSObject {
    private var proxy: Proxy?
    private var iconNames = [String]()
    private weak var controller: UIViewController?

    func load(proxy: Proxy, iconNames: [String], controller: UIViewController) {
        self.proxy = proxy
        self.iconNames = iconNames
        self.controller = controller
    }
}

extension IconPickerCollectionViewDelegate: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let iconName = iconNames[safe: indexPath.row],
            let proxy = proxy else {
                return
        }
        collectionView.cellForItem(at: indexPath)?.backgroundColor = UIColor.blue
        DB.setIcon(to: iconName, forProxy: proxy) { _ in }
        controller?.dismiss(animated: true)
    }
}
