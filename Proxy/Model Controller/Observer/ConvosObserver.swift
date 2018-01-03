import FirebaseDatabase

class ConvosObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private weak var manager: ConvosManaging?
    private var uid: String?
    private var proxyKey: String?
    private var loading = true

    func observe(uid: String, proxyKey: String?, manager: ConvosManaging, querySize: UInt = Setting.querySize) {
        stopObserving()
        self.uid = uid
        self.proxyKey = proxyKey
        self.manager = manager
        ref = DB.makeReference(Child.convos, uid)
        handle = ref?.queryOrdered(byChild: Child.timestamp).queryLimited(toLast: querySize).observe(.value, with: { [weak self] (data) in
            self?.loading = true
            self?.manager?.convos = data.toConvosArray(uid: uid, proxyKey: proxyKey).reversed()
            self?.loading = false
        })

    }

    func loadConvos(endingAtTimestamp timestamp: Double, querySize: UInt) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrdered(byChild: Child.timestamp).queryEnding(atValue: timestamp).queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { [weak self] (data) in
            guard let uid = self?.uid else {
                return
            }
            var convos = data.toConvosArray(uid: uid, proxyKey: self?.proxyKey)
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
