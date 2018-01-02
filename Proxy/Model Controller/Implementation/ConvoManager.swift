import UIKit

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

    func load(convoOwnerId: String, convoKey: String, navigationItem: UINavigationItem, collectionView: UICollectionView) {
        self.navigationItem = navigationItem
        self.collectionView = collectionView
        observer.observe(convoOwnerId: convoOwnerId, convoKey: convoKey, manager: self)
    }

    func load(convoOwnerId: String, convoKey: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(convoOwnerId: convoOwnerId, convoKey: convoKey, manager: self)
    }
}
