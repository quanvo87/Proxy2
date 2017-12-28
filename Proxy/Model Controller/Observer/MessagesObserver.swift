import FirebaseDatabase

class MessagesObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private weak var manager: MessagesManaging?
    var loading = true

    func load(convoKey: String, manager: MessagesManaging) {
        ref = DB.makeReference(Child.messages, convoKey)
        self.manager = manager
    }

    func observe() {
        loading = true
        stopObserving()
        handle = ref?.queryLimited(toLast: Setting.messagesPageSize).queryOrdered(byChild: Child.timestamp).observe(.value, with: { (data) in
            self.manager?.messages = data.toMessagesArray()
            self.manager?.collectionView?.scrollToBottom()
            self.loading = false
        })
    }

    func getMessages(startingAtMessageWithId id: String, count: UInt = Setting.messagesPageSize) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrderedByKey().queryEnding(atValue: id).queryLimited(toLast: count).observeSingleEvent(of: .value, with: { (data) in
            let olderMessages = data.toMessagesArray()
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
