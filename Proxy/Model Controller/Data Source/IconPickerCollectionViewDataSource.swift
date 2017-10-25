import UIKit

class IconPickerCollectionViewDataSource: NSObject {
    private var iconNames = [String]()

    func load(_ iconNames: [String]) {
        self.iconNames = iconNames
    }
}

extension IconPickerCollectionViewDataSource: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Name.iconPickerCollectionViewCell, for: indexPath) as? IconPickerCollectionViewCell,
            let iconName = iconNames[safe: indexPath.row] else {
                return collectionView.dequeueReusableCell(withReuseIdentifier: Name.iconPickerCollectionViewCell, for: indexPath)
        }
        cell.load(iconName)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return iconNames.count
    }
}
