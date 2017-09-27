import FirebaseDatabase

class ConvosObserver: ReferenceObserving {
    let ref: DatabaseReference?
    var handle: DatabaseHandle?
    weak var manager: ConvosManaging?

    init(convosOwner owner: String, manager: ConvosManaging) {
        self.manager = manager
        ref = DB.makeReference(Child.convos, owner)
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self] (data) in
            self?.manager?.convos = data.toConvosArray(filtered: true).reversed()
        })
    }

    deinit {
        stopObserving()
    }
}
