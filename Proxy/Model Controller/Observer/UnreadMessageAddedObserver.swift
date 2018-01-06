import FirebaseDatabase

class UnreadMessageAddedObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String,
                 presenceManager: PresenceManaging,
                 proxiesManager: ProxiesManaging,
                 unreadMessagesManager: UnreadMessagesManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, Child.unreadMessages)
        handle = ref?.observe(.childAdded, with: { [weak presenceManager, weak proxiesManager, weak unreadMessagesManager] (data) in
            guard
                let message = Message(data),
                let proxiesManager = proxiesManager else {
                    return
            }
            guard proxiesManager.proxies.contains(where: { $0.key == message.receiverProxyKey }) else {
                DB.deleteUnreadMessage(message) { _ in }
                return
            }
            if presenceManager?.presentInConvo == message.parentConvoKey {
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
