import MessageKit
import UIKit

protocol MessagesManaging: class {
    var messages: [Message] { get set }
    var collectionView: MessagesCollectionView? { get }
    func loadMessages(endingAtMessageWithId id: String, querySize: UInt)
}

class MessagesManager: MessagesManaging {
    var messages = [Message]()
    weak var collectionView: MessagesCollectionView?
    private let observer = MessagesObserver()

    func load(convoKey: String, collectionView: MessagesCollectionView) {
        self.collectionView = collectionView
        observer.observe(convoKey: convoKey, manager: self)
    }

    func loadMessages(endingAtMessageWithId id: String, querySize: UInt) {
        observer.loadMessages(endingAtMessageWithId: id, querySize: querySize)
    }
}
