import FirebaseDatabase

protocol BlockedUserObserving: ReferenceObserving {
    func observe(senderId: String, receiverId: String, completion: @escaping (Bool) -> Void)
}

class BlockedUserObserver: BlockedUserObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(senderId: String, receiverId: String, completion: @escaping (Bool) -> Void) {
        stopObserving()
        ref = try? Shared.firebaseHelper.makeReference(Child.users, senderId, Child.blockedUsers, receiverId)
        handle = ref?.observe(.value) { data in
            completion(data.exists())
        }
    }

    deinit {
        stopObserving()
    }
}
