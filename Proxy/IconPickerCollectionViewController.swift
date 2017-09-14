import UIKit

class IconPickerCollectionViewController: UICollectionViewController {
    private var dataSource: IconPickerCollectionViewDataSource?
    private var delegate: IconPickerCollectionViewDelegate?
    var proxy: Proxy?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.rightBarButtonItem = UIBarButtonItem.makeButton(target: self, action: #selector(cancelPickingIcon), imageName: .cancel)
        navigationItem.title = "Select An Icon"

        guard
            let collectionView = collectionView,
            let proxy = proxy else {
                return
        }

        dataSource = IconPickerCollectionViewDataSource(collectionView)
        delegate = IconPickerCollectionViewDelegate(collectionViewController: self, proxy: proxy)

        for case let scrollView as UIScrollView in collectionView.subviews {
            scrollView.delaysContentTouches = false
        }

        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 60, height: 90)

        collectionView.backgroundColor = UIColor.white
        collectionView.delaysContentTouches = false
        collectionView.setCollectionViewLayout(flowLayout, animated: true)
        collectionView.reloadData()
    }
    
    @objc func cancelPickingIcon() {
        dismiss(animated: true)
    }
}
