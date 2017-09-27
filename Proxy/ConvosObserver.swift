import FirebaseDatabase

class ConvosObserver: ReferenceObserving {
    var handle: DatabaseHandle?
    var ref: DatabaseReference?

    func observe(convosOwner owner: String, manager: ConvosManaging) {
        stopObserving()
        ref = DB.makeReference(Child.convos, owner)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak manager = manager] (data) in
            manager?.convos = data.toConvosArray(filtered: true).reversed()
        })
    }

    deinit {
        stopObserving()
    }
}
