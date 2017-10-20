import UIKit

class IconPickerCollectionViewDataSource: NSObject, UICollectionViewDataSource {
    var icons: [String] {
        return Shared.shared.proxyIconNames
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Name.iconPickerCollectionViewCell, for: indexPath) as? IconPickerCollectionViewCell,
            let icon = icons[safe: indexPath.row] else {
                return collectionView.dequeueReusableCell(withReuseIdentifier: Name.iconPickerCollectionViewCell, for: indexPath)
        }
        cell.configure(icon)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return icons.count
    }
}
