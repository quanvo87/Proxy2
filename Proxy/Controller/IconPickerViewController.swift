import UIKit

class IconPickerViewController: UIViewController {
    private let collectionView: UICollectionView
    private let delegate = IconPickerCollectionViewDelegate()
    private let proxy: Proxy
    private lazy var dataSource = IconPickerCollectionViewDataSource(ProxyService.iconNames)

    init(_ proxy: Proxy) {
        self.proxy = proxy

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 90)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)

        delegate.load(iconNames: ProxyService.iconNames, proxy: proxy, controller: self)

        collectionView.backgroundColor = UIColor.white
        collectionView.dataSource = dataSource
        collectionView.delegate = delegate
        collectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        collectionView.register(UINib(nibName: Identifier.iconPickerCollectionViewCell, bundle: nil), forCellWithReuseIdentifier: Identifier.iconPickerCollectionViewCell)
        collectionView.reloadData()

        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self, action: #selector(close), imageName: ButtonName.cancel)
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
