import FirebaseDatabase

class ConvosObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private weak var manager: ConvosManaging?
    private var loading = true

    func observe(convosOwner: String, manager: ConvosManaging, querySize: UInt = Setting.querySize) {
        stopObserving()
        self.manager = manager
        ref = DB.makeReference(Child.convos, convosOwner)
        handle = ref?.queryOrdered(byChild: Child.timestamp).queryLimited(toLast: querySize).observe(.value, with: { [weak self] (data) in
            self?.loading = true
            self?.manager?.convos = data.asConvosArray.reversed()
            self?.loading = false
        })

    }

    func getConvos(endingAtTimestamp timestamp: Double, querySize: UInt = Setting.querySize) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrdered(byChild: Child.timestamp).queryEnding(atValue: timestamp).queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { [weak self] (data) in
            var convos = data.asConvosArray
            guard convos.count > 1 else {
                return
            }
            convos.removeLast(1)
            self?.manager?.convos += convos.reversed()
            self?.loading = false
        })
    }

    deinit {
        stopObserving()
    }
}
