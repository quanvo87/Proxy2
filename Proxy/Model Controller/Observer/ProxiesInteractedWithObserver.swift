import FirebaseDatabase

class ProxiesInteractedWithObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, manager: ProxiesInteractedWithCountManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, IncrementableUserProperty.proxiesInteractedWith.rawValue)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            manager?.proxiesInteractedWithCount = data.asNumberLabel
        })
    }

    deinit {
        stopObserving()
    }
}
