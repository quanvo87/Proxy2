import FirebaseDatabase

protocol BlockedUsersObserving: ReferenceObserving {
    func observe(uid: String, completion: @escaping ([BlockedUser]) -> Void)
}

class BlockedUsersObserver: BlockedUsersObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(uid: String, completion: @escaping ([BlockedUser]) -> Void) {
        stopObserving()
        ref = try? Shared.firebaseHelper.makeReference(Child.users, uid, Child.blockedUsers)
        handle = ref?.queryOrdered(byChild: Child.dateBlocked).observe(.value) { data in
            completion(data.asBlockedUsersArray.reversed())
        }
    }

    deinit {
        stopObserving()
    }
}
