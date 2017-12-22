import MessageKit
import UIKit

class MessagesManager: MessagesManaging {
    var messages = [MessageType]() {
        didSet {
            collectionView?.reloadData()
            collectionView?.scrollToBottom()
        }
    }

    private let observer = MessagesObserver()
    private weak var collectionView: MessagesCollectionView?

    func load(convoKey: String, collectionView: MessagesCollectionView) {
        self.collectionView = collectionView
        observer.observe(convoKey: convoKey, manager: self)
    }
}
