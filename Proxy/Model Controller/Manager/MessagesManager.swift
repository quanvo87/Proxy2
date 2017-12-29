import MessageKit
import UIKit

class MessagesManager: MessagesManaging {
    let observer = MessagesObserver()
    var messages = [Message]()
    weak var collectionView: MessagesCollectionView?

    func load(convoKey: String, collectionView: MessagesCollectionView) {
        self.collectionView = collectionView
        observer.load(convoKey: convoKey, manager: self)
        observer.observe()
    }
}
