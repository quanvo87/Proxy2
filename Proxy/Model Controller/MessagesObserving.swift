import FirebaseDatabase
import FirebaseHelper
import MessageKit

protocol MessagesObserving: ReferenceObserving {
    init(querySize: UInt)
    func load(convoKey: String, messagesCollectionView: MessagesCollectionView, messagesManager: MessagesManaging)
    func loadMessages(endingAtMessageId id: String,
                      messagesCollectionView: MessagesCollectionView,
                      messagesManager: MessagesManaging)
}

class MessagesObserver: MessagesObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let querySize: UInt
    private var loading = true

    required init(querySize: UInt = Setting.querySize) {
        self.querySize = querySize
    }

    func load(convoKey: String, messagesCollectionView: MessagesCollectionView, messagesManager: MessagesManaging) {
        stopObserving()
        ref = try? FirebaseHelper.main.makeReference(Child.messages, convoKey)
        handle = ref?
            .queryOrdered(byChild: Child.timestamp)
            .queryLimited(toLast: querySize)
            .observe(.value) { [weak self, weak messagesCollectionView, weak messagesManager] (data) in
                self?.loading = true
                messagesManager?.messages = data.toMessagesArray
                messagesCollectionView?.reloadData()
                messagesCollectionView?.scrollToBottom()
                self?.loading = false
        }
    }

    func loadMessages(endingAtMessageId id: String,
                      messagesCollectionView: MessagesCollectionView,
                      messagesManager: MessagesManaging) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrderedByKey()
            .queryEnding(atValue: id)
            .queryLimited(toLast: querySize)
            .observeSingleEvent(of: .value) { [weak self, weak messagesCollectionView, weak messagesManager] (data) in
                var olderMessages = data.toMessagesArray
                guard olderMessages.count > 1 else {
                    return
                }
                olderMessages.removeLast(1)
                let currentMessages = messagesManager?.messages ?? []
                messagesManager?.messages = olderMessages + currentMessages
                messagesCollectionView?.reloadDataAndKeepOffset()
                self?.loading = false
        }
    }

    deinit {
        stopObserving()
    }
}
