import MessageKit
import UIKit

class MessagesManager: MessagesManaging {
    var messages = [Message]()

    let observer = MessagesObserver()
    weak var collectionView: MessagesCollectionView?

    func load(convoKey: String, collectionView: MessagesCollectionView) {
        self.collectionView = collectionView
        observer.load(convoKey: convoKey, manager: self)
        observer.observe()
    }
}
