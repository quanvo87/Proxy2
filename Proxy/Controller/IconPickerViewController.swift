import UIKit

class IconPickerViewController: UIViewController {
    private let dataSource = IconPickerCollectionViewDataSource()
    private let delegate = IconPickerCollectionViewDelegate()
    private let collectionView: UICollectionView
    private let proxy: Proxy

    init(_ proxy: Proxy) {
        self.proxy = proxy

        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 90)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.dataSource = dataSource
        collectionView.delegate = delegate
        collectionView.register(UINib(nibName: Name.iconPickerCollectionViewCell, bundle: nil), forCellWithReuseIdentifier: Name.iconPickerCollectionViewCell)

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "Select An Icon"
        navigationItem.rightBarButtonItem = UIBarButtonItem.makeButton(target: self, action: #selector(closeIconPicker), imageName: .cancel)

        dataSource.load(ProxyService.iconNames)
        delegate.load(iconNames: ProxyService.iconNames, proxy: proxy, controller: self)

        collectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        collectionView.reloadData()

        view.addSubview(collectionView)
    }
    
    @objc func closeIconPicker() {
        dismiss(animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
