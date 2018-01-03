import MessageKit
import UIKit

protocol MessagesManaging: class {
    var messages: [Message] { get set }
    var collectionView: MessagesCollectionView? { get }
}

class MessagesManager: MessagesManaging {
    let observer = MessagesObserver()
    var messages = [Message]()
    weak var collectionView: MessagesCollectionView?

    func load(convoKey: String, collectionView: MessagesCollectionView) {
        self.collectionView = collectionView
        observer.observe(convoKey: convoKey, manager: self)
    }
}
