import FirebaseDatabase

class MessagesObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private weak var manager: MessagesManaging?
    private var loading = true

    func observe(convoKey: String, manager: MessagesManaging, querySize: UInt = Setting.querySize) {
        stopObserving()
        loading = true
        self.manager = manager
        ref = DB.makeReference(Child.messages, convoKey)
        handle = ref?.queryOrdered(byChild: Child.timestamp).queryLimited(toLast: querySize).observe(.value, with: { (data) in
            self.manager?.messages = data.toMessagesArray(self.ref)
            self.manager?.collectionView?.reloadData()
            self.manager?.collectionView?.scrollToBottom()
            self.loading = false
        })
    }

    func getMessages(endingAtMessageWithId id: String, querySize: UInt = Setting.querySize) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrderedByKey().queryEnding(atValue: id).queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { (data) in
            var olderMessages = data.toMessagesArray(self.ref)
            guard olderMessages.count > 1 else {
                return
            }
            olderMessages.removeLast(1)
            let currentMessages = self.manager?.messages ?? []
            self.manager?.messages = olderMessages + currentMessages
            self.manager?.collectionView?.reloadDataAndKeepOffset()
            self.loading = false
        })
    }

    deinit {
        stopObserving()
    }
}
