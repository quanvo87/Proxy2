import FirebaseDatabase

protocol ConvosObsering: ReferenceObserving {
    init(querySize: UInt)
    func load(manager: ConvosManaging, uid: String, proxyKey: String?)
    func loadConvos(endingAtTimestamp timestamp: Double,
                    manager: ConvosManaging,
                    uid: String,
                    proxyKey: String?)
}

class ConvosObserver: ConvosObsering {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let querySize: UInt
    private var loading = true

    required init(querySize: UInt = Setting.querySize) {
        self.querySize = querySize
    }

    func load(manager: ConvosManaging, uid: String, proxyKey: String?) {
        stopObserving()
        ref = FirebaseHelper.makeReference(Child.convos, uid)
        handle = ref?
            .queryOrdered(byChild: Child.timestamp)
            .queryLimited(toLast: querySize)
            .observe(.value) { [weak self, weak manager] (data) in
                self?.loading = true
                manager?.convos = data.toConvosArray(uid: uid, proxyKey: proxyKey).reversed()
                self?.loading = false
        }
    }

    func loadConvos(endingAtTimestamp timestamp: Double,
                    manager: ConvosManaging,
                    uid: String,
                    proxyKey: String?) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrdered(byChild: Child.timestamp)
            .queryEnding(atValue: timestamp)
            .queryLimited(toLast: querySize)
            .observeSingleEvent(of: .value) { [weak self, weak manager] (data) in
                var convos = data.toConvosArray(uid: uid, proxyKey: proxyKey)
                guard convos.count > 1 else {
                    return
                }
                convos.removeLast(1)
                manager?.convos += convos.reversed()
                self?.loading = false
        }
    }

    deinit {
        stopObserving()
    }
}
