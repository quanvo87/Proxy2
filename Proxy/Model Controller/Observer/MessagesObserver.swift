import FirebaseDatabase

class MessagesObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private weak var manager: MessagesManaging?
    private var loading = true

    func load(convoKey: String, manager: MessagesManaging) {
        ref = DB.makeReference(Child.messages, convoKey)
        self.manager = manager
    }

    func observe() {
        loading = true
        stopObserving()
        handle = ref?.queryOrdered(byChild: Child.timestamp).queryLimited(toLast: Setting.querySize).observe(.value, with: { (data) in
            self.manager?.messages = data.toMessagesArray()
            self.manager?.collectionView?.reloadData()
            self.manager?.collectionView?.scrollToBottom()
            self.loading = false
        })
    }

    func getMessages(startingAtMessageWithId id: String, count: UInt = Setting.querySize) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrderedByKey().queryEnding(atValue: id).queryLimited(toLast: count).observeSingleEvent(of: .value, with: { (data) in
            var olderMessages = data.toMessagesArray()
            olderMessages.removeLast(1)
            let currentMessages = self.manager?.messages ?? []
            if !olderMessages.isEmpty {
                self.manager?.messages = olderMessages + currentMessages
                self.manager?.collectionView?.reloadDataAndKeepOffset()
            }
            self.loading = false
        })
    }

    deinit {
        stopObserving()
    }
}
