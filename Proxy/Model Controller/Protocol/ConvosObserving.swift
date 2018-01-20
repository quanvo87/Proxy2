import FirebaseDatabase

protocol ConvosObsering: ReferenceObserving {
    func load(proxyKey: String?, querySize: UInt, uid: String, manager: ConvosManaging?)
    func loadConvos(endingAtTimestamp timestamp: Double,
                    proxyKey: String?,
                    querySize: UInt,
                    uid: String,
                    manager: ConvosManaging?)
}

class ConvosObserver: ConvosObsering {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private var loading = true

    func load(proxyKey: String?, querySize: UInt, uid: String, manager: ConvosManaging?) {
        stopObserving()
        ref = DB.makeReference(Child.convos, uid)
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
                    proxyKey: String?,
                    querySize: UInt,
                    uid: String,
                    manager: ConvosManaging?) {
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
