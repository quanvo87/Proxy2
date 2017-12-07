import FirebaseDatabase

class ConvosObserver: ReferenceObserving {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?

    func observe(convosManager: ConvosManaging, convosOwner: String) {
        stopObserving()
        ref = DB.makeReference(Child.convos, convosOwner)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak convosManager = convosManager] (data) in
            convosManager?.convos = data.toConvosArray(filtered: true).reversed()
        })
    }

    deinit {
        stopObserving()
    }
}
