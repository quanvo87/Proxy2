import UIKit

class IconPickerViewController: UIViewController {
    private let collectionView: UICollectionView
    private let dataSource = IconPickerCollectionViewDataSource()
    private let delegate = IconPickerCollectionViewDelegate()
    private let proxy: Proxy

    init(_ proxy: Proxy) {
        self.proxy = proxy

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 90)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "Select An Icon"
        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self, action: #selector(close), imageName: ButtonName.cancel)

        dataSource.load(iconNames: ProxyService.iconNames)

        delegate.load(proxy: proxy, iconNames: ProxyService.iconNames, controller: self)

        collectionView.backgroundColor = UIColor.white
        collectionView.dataSource = dataSource
        collectionView.delegate = delegate
        collectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        collectionView.register(UINib(nibName: Identifier.iconPickerCollectionViewCell, bundle: nil), forCellWithReuseIdentifier: Identifier.iconPickerCollectionViewCell)
        collectionView.reloadData()
        
        view.addSubview(collectionView)
    }
    
    @objc func close() {
        dismiss(animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
