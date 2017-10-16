import UIKit

class IconPickerCollectionViewController: UICollectionViewController {
    private let dataSource = IconPickerCollectionViewDataSource()
    private let delegate = IconPickerCollectionViewDelegate()
    var proxy: Proxy?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 60, height: 90)
        collectionView?.backgroundColor = UIColor.white
        collectionView?.dataSource = dataSource
        collectionView?.delaysContentTouches = false
        collectionView?.reloadData()
        collectionView?.setCollectionViewLayout(layout, animated: true)
        delegate.load(proxy: proxy, controller: self)
        navigationItem.rightBarButtonItem = UIBarButtonItem.makeButton(target: self, action: #selector(cancelPickingIcon), imageName: .cancel)
        navigationItem.title = "Select An Icon"
        for case let scrollView as UIScrollView in collectionView?.subviews ?? [] {
            scrollView.delaysContentTouches = false
        }
    }
    
    @objc func cancelPickingIcon() {
        dismiss(animated: true)
    }
}
