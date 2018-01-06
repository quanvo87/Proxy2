import UIKit

protocol ConvoManaging: class {
    var convo: Convo? { get set }
}

class ConvoManager: ConvoManaging {
    var convo: Convo? {
        didSet {
            collectionView?.reloadData()
            navigationItem?.title = convo?.receiverDisplayName
            tableView?.reloadData()
        }
    }

    private let observer = ConvoObserver()
    private weak var collectionView: UICollectionView?
    private weak var navigationItem: UINavigationItem?
    private weak var tableView: UITableView?

    func load(uid: String, key: String, collectionView: UICollectionView, navigationItem: UINavigationItem, closer: Closing) {
        self.collectionView = collectionView
        self.navigationItem = navigationItem
        observer.observe(uid: uid, key: key, manager: self, closer: closer)
    }

    func load(uid: String, key: String, tableView: UITableView, closer: Closing) {
        self.tableView = tableView
        observer.observe(uid: uid, key: key, manager: self, closer: closer)
    }
}
