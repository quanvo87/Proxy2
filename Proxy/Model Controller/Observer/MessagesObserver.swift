import FirebaseDatabase

class MessagesObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private weak var manager: MessagesManaging?
    private var loading = true
    private var loadedAll = false

    func observe(convoKey: String, manager: MessagesManaging) {
        stopObserving()
        loading = true
        ref = DB.makeReference(Child.messages, convoKey)
        handle = ref?.queryOrdered(byChild: Child.timestamp).queryLimited(toLast: Setting.querySize).observe(.value, with: { (data) in
            self.manager?.messages = data.toMessagesArray()
            self.manager?.collectionView?.reloadData()
            self.manager?.collectionView?.scrollToBottom()
            self.loading = false
        })
        self.manager = manager
    }

    func getMessages(endingAtMessageWithId id: String, querySize: UInt = Setting.querySize) {
        guard !loading, !loadedAll else {
            return
        }
        loading = true
        ref?.queryOrderedByKey().queryEnding(atValue: id).queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { (data) in
            defer {
                self.loading = false
            }
            var olderMessages = data.toMessagesArray()
            if olderMessages.count == 1 {
                self.loadedAll = true
                return
            }
            olderMessages.removeLast(1)
            let currentMessages = self.manager?.messages ?? []
            if !olderMessages.isEmpty {
                self.manager?.messages = olderMessages + currentMessages
                self.manager?.collectionView?.reloadDataAndKeepOffset()
            }
        })
    }

    deinit {
        stopObserving()
    }
}
