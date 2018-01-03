import UIKit

protocol ConvoManaging: class {
    var convo: Convo? { get set }
}

class ConvoManager: ConvoManaging {
    var convo: Convo? {
        didSet {
            navigationItem?.title = convo?.receiverDisplayName
            collectionView?.reloadData()
            tableView?.reloadData()
        }
    }

    private let observer = ConvoObserver()
    private weak var navigationItem: UINavigationItem?
    private weak var collectionView: UICollectionView?
    private weak var tableView: UITableView?

    func load(uid: String, key: String, navigationItem: UINavigationItem, collectionView: UICollectionView, closer: Closing) {
        self.navigationItem = navigationItem
        self.collectionView = collectionView
        observer.observe(uid: uid, key: key, manager: self, closer: closer)
    }

    func load(uid: String, key: String, tableView: UITableView, closer: Closing) {
        self.tableView = tableView
        observer.observe(uid: uid, key: key, manager: self, closer: closer)
    }
}
