import UIKit

class CollectionViewReloader: ViewReloading {
    weak var collectionView: UICollectionView?

    func reload() {
        collectionView?.reloadData()
    }
}
