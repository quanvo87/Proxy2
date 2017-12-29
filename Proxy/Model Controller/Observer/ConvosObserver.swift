import FirebaseDatabase

class ConvosObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private weak var manager: ConvosManaging?
    private var loading = true
    private var loadedAll = false

    func observe(convosOwner: String, manager: ConvosManaging) {
        loading = true
        stopObserving()
        ref = DB.makeReference(Child.convos, convosOwner)
        handle = ref?.queryOrdered(byChild: Child.timestamp).queryLimited(toLast: Setting.querySize).observe(.value, with: { [weak manager = manager] (data) in
            manager?.convos = data.toConvosArray().reversed()
            manager?.tableView?.reloadData()
            self.loading = false
        })
    }

    deinit {
        stopObserving()
    }
}
