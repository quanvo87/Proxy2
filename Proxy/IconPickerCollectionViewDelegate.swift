import UIKit

class IconPickerCollectionViewDelegate: NSObject {
    weak var controller: IconPickerCollectionViewController?

    func load(_ controller: IconPickerCollectionViewController) {
        self.controller = controller
        controller.collectionView?.delegate = self
    }
}

extension IconPickerCollectionViewDelegate: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.blue
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.white
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard
            let icon = Shared.shared.proxyIconNames[safe: indexPath.row],
            let proxy = controller?.proxy else {
                return
        }
        DBProxy.setIcon(to: icon, forProxy: proxy) { _ in }
        controller?.dismiss(animated: true)
    }
}
