import FirebaseDatabase

class ProxiesInteractedWithObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(uid: String, manager: ProxiesInteractedWithManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, IncrementableUserProperty.proxiesInteractedWith.rawValue)
        handle = ref?.observe(.value) { [weak manager] (data) in
            manager?.proxiesInteractedWithCount = data.asNumberLabel
        }
    }

    deinit {
        stopObserving()
    }
}
