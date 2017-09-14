import UIKit

class IconPickerCollectionViewDelegate: NSObject {
    private let proxy: Proxy
    private weak var collectionViewController: UICollectionViewController?

    init(collectionViewController: UICollectionViewController, proxy: Proxy) {
        self.proxy = proxy
        super.init()
        collectionViewController.collectionView?.delegate = self
        self.collectionViewController = collectionViewController
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
        guard let icon = Shared.shared.proxyIconNames[safe: indexPath.row] else { return }
        DBProxy.setIcon(to: icon, forProxy: proxy) { _ in }
        collectionViewController?.dismiss(animated: true)
    }
}
