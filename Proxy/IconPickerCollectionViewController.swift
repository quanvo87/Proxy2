import UIKit

class IconPickerCollectionViewController: UICollectionViewController {
    let dataSource = IconPickerCollectionViewDataSource()
    let delegate = IconPickerCollectionViewDelegate()
    var proxy: Proxy?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 60, height: 90)

        collectionView?.backgroundColor = UIColor.white
        collectionView?.delaysContentTouches = false
        collectionView?.reloadData()
        collectionView?.setCollectionViewLayout(flowLayout, animated: true)

        navigationItem.rightBarButtonItem = UIBarButtonItem.makeButton(target: self, action: #selector(cancelPickingIcon), imageName: .cancel)
        navigationItem.title = "Select An Icon"

        for case let scrollView as UIScrollView in collectionView?.subviews ?? [] {
            scrollView.delaysContentTouches = false
        }

        setupDataSource()
        setupDelegate()
    }
    
    @objc func cancelPickingIcon() {
        dismiss(animated: true)
    }
}

private extension IconPickerCollectionViewController {
    func setupDataSource() {
        collectionView?.dataSource = dataSource
    }

    func setupDelegate() {
        collectionView?.delegate = delegate
        delegate.controller = self
        delegate.proxy = proxy
    }
}
