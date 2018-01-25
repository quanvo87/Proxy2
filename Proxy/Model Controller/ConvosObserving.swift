import FirebaseDatabase

protocol ConvosObsering: ReferenceObserving {
    init(querySize: UInt)
    func load(convosOwnerId: String, proxyKey: String?, convosManager: ConvosManaging)
    func loadConvos(endingAtTimestamp timestamp: Double,
                    proxyKey: String?,
                    convosManager: ConvosManaging)
}

class ConvosObserver: ConvosObsering {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let querySize: UInt
    private var loading = true

    required init(querySize: UInt = Setting.querySize) {
        self.querySize = querySize
    }

    func load(convosOwnerId: String, proxyKey: String?, convosManager: ConvosManaging) {
        stopObserving()
        ref = FirebaseHelper.makeReference(Child.convos, convosOwnerId)
        handle = ref?
            .queryOrdered(byChild: Child.timestamp)
            .queryLimited(toLast: querySize)
            .observe(.value) { [weak self, weak convosManager] (data) in
                self?.loading = true
                convosManager?.convos = data.toConvosArray(proxyKey: proxyKey).reversed()
                self?.loading = false
        }
    }

    func loadConvos(endingAtTimestamp timestamp: Double,
                    proxyKey: String?,
                    convosManager: ConvosManaging) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrdered(byChild: Child.timestamp)
            .queryEnding(atValue: timestamp)
            .queryLimited(toLast: querySize)
            .observeSingleEvent(of: .value) { [weak self, weak convosManager] (data) in
                var convos = data.toConvosArray(proxyKey: proxyKey)
                guard convos.count > 1 else {
                    return
                }
                convos.removeLast(1)
                convosManager?.convos += convos.reversed()
                self?.loading = false
        }
    }

    deinit {
        stopObserving()
    }
}
