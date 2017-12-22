import UIKit

class ConvoManager: ConvoManaging {
    var convo: Convo? {
        didSet {
            collectionView?.reloadData()
            tableView?.reloadData()
        }
    }

    private let observer = ConvoObserver()
    private weak var collectionView: UICollectionView?
    private weak var tableView: UITableView?

    func load(convoOwnerId: String, convoKey: String, collectionView: UICollectionView) {
        self.collectionView = collectionView
        observer.observe(convoOwnerId: convoOwnerId, convoKey: convoKey, manager: self)
    }

    func load(convoOwnerId: String, convoKey: String, tableView: UITableView) {
        self.tableView = tableView
        observer.observe(convoOwnerId: convoOwnerId, convoKey: convoKey, manager: self)
    }
}
