import MessageKit
import UIKit

class MessagesManager: MessagesManaging {
    var messages = [MessageType]() {
        didSet {
            collectionView?.reloadData()
        }
    }

    private let messagesObserver = MessagesObserver()
    private weak var collectionView: UICollectionView?

    func load(convoKey: String, collectionView: UICollectionView) {
        self.collectionView = collectionView
        messagesObserver.observe(convoKey: convoKey, manager: self)
    }
}
