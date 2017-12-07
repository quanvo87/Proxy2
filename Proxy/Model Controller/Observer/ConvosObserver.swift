import FirebaseDatabase

class ConvosObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    func observe(convosOwner: String, manager: ConvosManaging) {
        stopObserving()
        ref = DB.makeReference(Child.convos, convosOwner)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak manager = manager] (data) in
            manager?.convos = data.toConvosArray(filtered: true).reversed()
        })
    }

    deinit {
        stopObserving()
    }
}
