import FirebaseDatabase

class MessagesObserver: MessagesObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private let querySize: UInt
    private let convoKey: String
    private var loading = true
    private weak var manager: MessagesManaging?

    init(convoKey: String, querySize: UInt = Setting.querySize, manager: MessagesManaging?) {
        self.convoKey = convoKey
        self.querySize = querySize
        self.manager = manager
        ref = DB.makeReference(Child.messages, convoKey)
    }

    func observe() {
        stopObserving()
        handle = ref?.queryOrdered(byChild: Child.timestamp).queryLimited(toLast: querySize).observe(.value) { [weak self] (data) in
            self?.loading = true
            self?.manager?.messages = data.asMessagesArray
            self?.manager?.messagesCollectionView.reloadData()
            self?.manager?.messagesCollectionView.scrollToBottom()
            self?.loading = false
        }
    }

    func loadMessages(endingAtMessageWithId id: String) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrderedByKey().queryEnding(atValue: id).queryLimited(toLast: querySize).observeSingleEvent(of: .value) { [weak self] (data) in
            var olderMessages = data.asMessagesArray
            guard olderMessages.count > 1 else {
                return
            }
            olderMessages.removeLast(1)
            let currentMessages = self?.manager?.messages ?? []
            self?.manager?.messages = olderMessages + currentMessages
            self?.manager?.messagesCollectionView.reloadDataAndKeepOffset()
            self?.loading = false
        }
    }

    deinit {
        stopObserving()
    }
}
