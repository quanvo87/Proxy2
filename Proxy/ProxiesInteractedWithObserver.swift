import FirebaseDatabase

class ProxiesInteractedWithObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(uid: String, manager: ProxiesInteractedWithManaging) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, IncrementableUserProperty.proxiesInteractedWith.rawValue)
        handle = ref?.observe(.value, with: { [weak manager = manager] (data) in
            if let count = data.value as? UInt {
                manager?.proxiesInteractedWithCount = count.asStringWithCommas
            }
        })
    }

    deinit {
        stopObserving()
    }
}
