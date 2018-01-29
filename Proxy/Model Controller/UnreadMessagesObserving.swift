import FirebaseDatabase
import FirebaseHelper

protocol UnreadMessagesObserving {
    func load(uid: String, unreadMessagesManager: UnreadMessagesManaging)
}

class UnreadMessagesObserver: UnreadMessagesObserving {
    private var ref: DatabaseReference?
    private var addedHandle: DatabaseHandle?
    private var removedHandle: DatabaseHandle?

    func load(uid: String, unreadMessagesManager: UnreadMessagesManaging) {
        stopObserving()
        ref = try? FirebaseHelper.main.makeReference(Child.userInfo, uid, Child.unreadMessages)
        addedHandle = ref?.observe(.childAdded) { [weak unreadMessagesManager] (data) in
            guard let message = try? Message(data) else {
                FirebaseHelper.main.delete(Child.userInfo, uid, Child.unreadMessages, data.key) { _ in }
                return
            }
            unreadMessagesManager?.unreadMessageAdded(message)
        }
        removedHandle = ref?.observe(.childRemoved) { [weak unreadMessagesManager] (data) in
            guard let message = try? Message(data) else {
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
