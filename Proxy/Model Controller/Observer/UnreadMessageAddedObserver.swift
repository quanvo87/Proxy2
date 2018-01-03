import FirebaseDatabase

class UnreadMessageAddedObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, container: DependencyContaining) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, Child.unreadMessages)
        handle = ref?.observe(.childAdded, with: { (data) in
            guard let message = Message(data) else {
                return
            }
            guard container.proxiesManager.proxies.contains(where: { $0.key == message.receiverProxyKey }) else {
                DB.deleteUnreadMessage(message) { _ in }
                return
            }
            if container.presenceManager.presentInConvo == message.parentConvoKey {
                DB.read(message) { _ in }
            } else {
                container.unreadMessagesManager.unreadMessages.append(message)
            }
        })
    }

    deinit {
        stopObserving()
    }
}
