import FirebaseDatabase

class UnreadMessageAddedObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, proxiesManager: ProxiesManaging, unreadMessagesManager: UnreadMessagesManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, Child.unreadMessages)
        handle = ref?.observe(.childAdded, with: { [weak proxiesManager, weak unreadMessagesManager] (data) in
            guard let proxiesManager = proxiesManager, let message = Message(data) else {
                return
            }

            guard proxiesManager.proxies.contains(where: { $0.key == message.receiverProxyKey }) else {
                DB.deleteUnreadMessage(message) { _ in }
                return
            }

            if unreadMessagesManager?.convosPresentIn[message.parentConvoKey] != nil {
                DB.read(message) { _ in }
            } else {
                unreadMessagesManager?.unreadMessages.append(message)
            }
        })
    }

    deinit {
        stopObserving()
    }
}
