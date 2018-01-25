import FirebaseDatabase

protocol UnreadMessagesObserving {
    func load(manager: UnreadMessagesManaging, uid: String)
}

class UnreadMessagesObserver: UnreadMessagesObserving {
    private var ref: DatabaseReference?
    private var addedHandle: DatabaseHandle?
    private var removedHandle: DatabaseHandle?

    func load(manager: UnreadMessagesManaging, uid: String) {
        stopObserving()
        ref = FirebaseHelper.makeReference(Child.userInfo, uid, Child.unreadMessages)
        addedHandle = ref?.observe(.childAdded) { [weak manager] (data) in
            guard let message = Message(data) else {
                FirebaseHelper.delete(Child.userInfo, uid, Child.unreadMessages, data.key) { _ in }
                return
            }
            manager?.unreadMessageAdded(message)
        }
        removedHandle = ref?.observe(.childRemoved) { [weak manager] (data) in
            guard let message = Message(data) else {
                return
            }
            manager?.unreadMessageRemoved(message)
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
