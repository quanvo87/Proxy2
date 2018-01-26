import FirebaseDatabase

protocol UnreadMessagesObserving {
    func load(uid: String, unreadMessagesManager: UnreadMessagesManaging)
}

class UnreadMessagesObserver: UnreadMessagesObserving {
    private var ref: DatabaseReference?
    private var addedHandle: DatabaseHandle?
    private var removedHandle: DatabaseHandle?

    func load(uid: String, unreadMessagesManager: UnreadMessagesManaging) {
        stopObserving()
        ref = FirebaseHelper.makeReference(Child.userInfo, uid, Child.unreadMessages)
        addedHandle = ref?.observe(.childAdded) { [weak unreadMessagesManager] (data) in
            guard let message = Message(data) else {
                FirebaseHelper.delete(Child.userInfo, uid, Child.unreadMessages, data.key) { _ in }
                return
            }
            unreadMessagesManager?.unreadMessageAdded(message)
        }
        removedHandle = ref?.observe(.childRemoved) { [weak unreadMessagesManager] (data) in
            guard let message = Message(data) else {
                return
            }
            unreadMessagesManager?.unreadMessageRemoved(message)
        }
    }

    private func stopObserving() {
        if let addedHandle = addedHandle {
            ref?.removeObserver(withHandle: addedHandle)
        }
        if let removedHandle = removedHandle {
            ref?.removeObserver(withHandle: removedHandle)
        }
    }

    deinit {
        stopObserving()
    }
}