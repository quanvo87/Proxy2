import UIKit

class IconPickerCollectionViewController: UICollectionViewController {
    let dataSource = IconPickerCollectionViewDataSource()
    let delegate = IconPickerCollectionViewDelegate()
    var proxy: Proxy?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem.makeButton(target: self, action: #selector(cancelPickingIcon), imageName: .cancel)
        navigationItem.title = "Select An Icon"

        guard let collectionView = collectionView else { return }

        dataSource.load(collectionView)
        delegate.load(self)

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 60, height: 90)

        collectionView.backgroundColor = UIColor.white
        collectionView.delaysContentTouches = false
        collectionView.setCollectionViewLayout(flowLayout, animated: true)
        collectionView.reloadData()

        for case let scrollView as UIScrollView in collectionView.subviews {
            scrollView.delaysContentTouches = false
        }
    }
    
    @objc func cancelPickingIcon() {
        dismiss(animated: true)
    }
}
