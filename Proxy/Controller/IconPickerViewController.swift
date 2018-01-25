import UIKit

class IconPickerViewController: UIViewController {
    private let collectionView: UICollectionView
    private let database: Database
    private let proxy: Proxy
    private let proxyPropertyGenerator: ProxyPropertyGenerating

    init(database: Database = Firebase(),
         proxy: Proxy,
         proxyPropertyGenerator: ProxyPropertyGenerating = ProxyPropertyGenerator()) {
        self.database = database
        self.proxy = proxy
        self.proxyPropertyGenerator = proxyPropertyGenerator

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

        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self,
                                                                 action: #selector(close),
                                                                 imageName: ButtonName.cancel)
        navigationItem.title = "Select An Icon"

        view.addSubview(collectionView)
    }

    @objc private func close() {
        dismiss(animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UICollectionViewDataSource
extension IconPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Identifier.iconPickerCollectionViewCell, for: indexPath) as? IconPickerCollectionViewCell,
            let iconName = proxyPropertyGenerator.iconNames[safe: indexPath.row] else {
                return collectionView.dequeueReusableCell(withReuseIdentifier: Identifier.iconPickerCollectionViewCell, for: indexPath)
        }
        cell.load(iconName)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return proxyPropertyGenerator.iconNames.count
    }
}

// MARK: - UICollectionViewDelegate
extension IconPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let iconName = proxyPropertyGenerator.iconNames[safe: indexPath.row] else {
            return
        }
        collectionView.cellForItem(at: indexPath)?.backgroundColor = UIColor.blue
        database.setIcon(to: iconName, for: proxy) { _ in }
        dismiss(animated: true)
    }
}
