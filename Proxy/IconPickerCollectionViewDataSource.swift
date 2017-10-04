import UIKit

class IconPickerCollectionViewDataSource: NSObject {
    func load(_ collectionView: UICollectionView?) {
        collectionView?.dataSource = self
        collectionView?.reloadData()
    }
}

extension IconPickerCollectionViewDataSource: UICollectionViewDataSource {
    var icons: [String] {
        return Shared.shared.proxyIconNames
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifier.iconPickerCollectionViewCell, for: indexPath) as? IconPickerCollectionViewCell,
            let icon = icons[safe: indexPath.row] else {
                return collectionView.dequeueReusableCell(withReuseIdentifier: Identifier.iconPickerCollectionViewCell, for: indexPath)
        }
        cell.configure(icon)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return icons.count
    }
}
