import FirebaseDatabase

class ConvosObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var manager: ConvosManaging?
    private(set) var handle: DatabaseHandle?

    init(manager: ConvosManaging, owner: String) {
        self.manager = manager
        ref = DB.makeReference(Child.convos, owner)
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self] (data) in
            self?.manager?.setConvos(data.toConvosArray(filtered: true).reversed())
        })
    }

    deinit {
        stopObserving()
    }
}

protocol ConvosManaging: class {
    var convos: [Convo] { get }
    func setConvos(_ convos: [Convo])
}
