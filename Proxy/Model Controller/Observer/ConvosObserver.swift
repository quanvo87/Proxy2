import FirebaseDatabase

class ConvosObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private weak var manager: ConvosManaging?
    private var loading = true

    func observe(convosOwner: String, manager: ConvosManaging, querySize: UInt = Setting.querySize) {
        stopObserving()
        loading = true
        ref = DB.makeReference(Child.convos, convosOwner)
        handle = ref?.queryOrdered(byChild: Child.timestamp).queryLimited(toLast: querySize).observe(.value, with: { [weak manager = manager] (data) in
            manager?.convos = data.toConvosArray().reversed()
            manager?.tableView?.reloadData()
            self.loading = false
        })
        self.manager = manager
    }

    func getConvos(endingAtTimestamp timestamp: Double, querySize: UInt = Setting.querySize) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrdered(byChild: Child.timestamp).queryEnding(atValue: timestamp).queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { (data) in
            var convos = data.toConvosArray()
            guard convos.count > 1 else {
                return
            }
            convos.removeLast(1)
            self.manager?.convos += convos.reversed()
            self.manager?.tableView?.reloadData()
            self.loading = false
        })
    }

    deinit {
        stopObserving()
    }
}
