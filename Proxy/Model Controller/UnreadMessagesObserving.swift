import FirebaseDatabase

enum UnreadMessageUpdate {
    case added(Message)
    case removed(Message)
}

protocol UnreadMessagesObserving {
    func observe(uid: String, completion: @escaping (UnreadMessageUpdate) -> Void)
}

class UnreadMessagesObserver: UnreadMessagesObserving {
    private var ref: DatabaseReference?
    private var addedHandle: DatabaseHandle?
    private var removedHandle: DatabaseHandle?

    func observe(uid: String, completion: @escaping (UnreadMessageUpdate) -> Void) {
        stopObserving()
        ref = try? Shared.firebaseHelper.makeReference(Child.userInfo, uid, Child.unreadMessages)
        addedHandle = ref?.observe(.childAdded) { data in
            do {
                completion(.added(try Message(data)))
            } catch {
                Shared.firebaseHelper.delete(Child.userInfo, uid, Child.unreadMessages, data.key) { _ in }
            }
        }
        removedHandle = ref?.observe(.childRemoved) { data in
            do {
                completion(.removed(try Message(data)))
            } catch {}
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
