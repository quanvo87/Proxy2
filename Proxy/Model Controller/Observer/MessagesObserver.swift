import FirebaseDatabase

class MessagesObserver: ReferenceObserving {
    private var loading = true
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private weak var manager: MessagesManaging?

    func observe(convoKey: String, manager: MessagesManaging, querySize: UInt = Setting.querySize) {
        stopObserving()
        self.manager = manager
        ref = DB.makeReference(Child.messages, convoKey)
        handle = ref?.queryOrdered(byChild: Child.timestamp).queryLimited(toLast: querySize).observe(.value, with: { [weak self] (data) in
            self?.loading = true
            self?.manager?.messages = data.asMessagesArray
            self?.manager?.collectionView?.reloadData()
            self?.manager?.collectionView?.scrollToBottom()
            self?.loading = false
        })
    }

    func loadMessages(endingAtMessageWithId id: String, querySize: UInt) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrderedByKey().queryEnding(atValue: id).queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { [weak self] (data) in
            var olderMessages = data.asMessagesArray
            guard olderMessages.count > 1 else {
                return
            }
            olderMessages.removeLast(1)
            let currentMessages = self?.manager?.messages ?? []
            self?.manager?.messages = olderMessages + currentMessages
            self?.manager?.collectionView?.reloadDataAndKeepOffset()
            self?.loading = false
        })
    }

    deinit {
        stopObserving()
    }
}
