import FirebaseDatabase

class ProxiesInteractedWithObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(proxiesInteractedWithManager: ProxiesInteractedWithCountManaging, uid: String) {
        stopObserving()
        ref = DB.makeReference(Child.userInfo, uid, IncrementableUserProperty.proxiesInteractedWith.rawValue)
        handle = ref?.observe(.value, with: { [weak proxiesInteractedWithManager = proxiesInteractedWithManager] (data) in
            if let count = data.value as? UInt {
                proxiesInteractedWithManager?.proxiesInteractedWithCount = count.asStringWithCommas
            }
        })
    }

    deinit {
        stopObserving()
    }
}
