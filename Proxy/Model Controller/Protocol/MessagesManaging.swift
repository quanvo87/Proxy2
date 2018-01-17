import FirebaseDatabase
import MessageKit

protocol MessagesManaging: ReferenceObserving {
    var messages: [Message] { get }
    func loadMessages(endingAtMessageId id: String)
}

class MessagesManager: MessagesManaging {
    let ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private (set) var messages = [Message]()
    private let convoKey: String
    private let querySize: UInt
    private var loading = true
    private weak var collectionView: MessagesCollectionView?

    init(convoKey: String,
         querySize: UInt = Setting.querySize,
         collectionView: MessagesCollectionView?) {
        self.convoKey = convoKey
        self.querySize = querySize
        self.collectionView = collectionView
        ref = DB.makeReference(Child.messages, convoKey)
        handle = ref?
            .queryOrdered(byChild: Child.timestamp)
            .queryLimited(toLast: querySize)
            .observe(.value) { [weak self] (data) in
                self?.loading = true
                self?.messages = data.asMessagesArray
                self?.collectionView?.reloadData()
                self?.collectionView?.scrollToBottom()
                self?.loading = false
        }
    }

    func loadMessages(endingAtMessageId id: String) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrderedByKey()
            .queryEnding(atValue: id)
            .queryLimited(toLast: querySize)
            .observeSingleEvent(of: .value) { [weak self] (data) in
                var olderMessages = data.asMessagesArray
                guard olderMessages.count > 1 else {
                    return
                }
                olderMessages.removeLast(1)
                let currentMessages = self?.messages ?? []
                self?.messages = olderMessages + currentMessages
                self?.collectionView?.reloadDataAndKeepOffset()
                self?.loading = false
        }
    }

    deinit {
        stopObserving()
    }
}
