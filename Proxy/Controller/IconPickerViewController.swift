import UIKit

class IconPickerViewController: UIViewController {
    private let collectionView: UICollectionView
    private let database: Database
    private let iconNames: [String]
    private let proxy: Proxy

    init(database: Database = Firebase(),
         iconNames: [String] = ProxyPropertyGenerator().iconNames,
         proxy: Proxy) {
        self.database = database
        self.iconNames = iconNames
        self.proxy = proxy

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 90)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)

        collectionView.backgroundColor = UIColor.white
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        collectionView.register(UINib(nibName: Identifier.iconPickerCollectionViewCell, bundle: nil),
                                forCellWithReuseIdentifier: Identifier.iconPickerCollectionViewCell)
        collectionView.reloadData()

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            target: self,
            action: #selector(close),
            image: UIImage(named: ButtonName.cancel)
        )
        navigationItem.title = "Select An Icon"

        view.addSubview(collectionView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension IconPickerViewController {
    @objc func close() {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension IconPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifier.iconPickerCollectionViewCell, for: indexPath) as? IconPickerCollectionViewCell,
            let iconName = iconNames[safe: indexPath.row] else {
                return collectionView.dequeueReusableCell(withReuseIdentifier: Identifier.iconPickerCollectionViewCell, for: indexPath)
        }
        cell.load(iconName)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return iconNames.count
    }
}

// MARK: - UICollectionViewDelegate
extension IconPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let iconName = iconNames[safe: indexPath.row] else {
            return
        }
        collectionView.cellForItem(at: indexPath)?.backgroundColor = Color.blue
        database.setIcon(to: iconName, for: proxy) { _ in }
        dismiss(animated: true)
    }
}
