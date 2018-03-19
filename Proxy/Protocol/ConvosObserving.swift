import FirebaseDatabase

protocol ConvosObsering: ReferenceObserving {
    init(querySize: UInt)
    func observe(convosOwnerId: String, proxyKey: String?, completion: @escaping ([Convo]) -> Void)
    func loadConvos(endingAtTimestamp timestamp: Double,
                    proxyKey: String?,
                    completion: @escaping ([Convo]) -> Void)
}

class ConvosObserver: ConvosObsering {
    private (set) var handle: DatabaseHandle?
    private (set) var ref: DatabaseReference?
    private let querySize: UInt
    private var loading = true

    required init(querySize: UInt = DatabaseOption.querySize) {
        self.querySize = querySize
    }

    func observe(convosOwnerId: String, proxyKey: String?, completion: @escaping ([Convo]) -> Void) {
        stopObserving()
        ref = try? Constant.firebaseHelper.makeReference(Child.convos, convosOwnerId)
        handle = ref?
            .queryLimited(toLast: querySize)
            .queryOrdered(byChild: Child.timestamp)
            .observe(.value) { [weak self] data in
                self?.loading = true
                completion(data.asConvosArray(proxyKey: proxyKey).reversed())
                self?.loading = false
        }
    }

    func loadConvos(endingAtTimestamp timestamp: Double,
                    proxyKey: String?,
                    completion: @escaping ([Convo]) -> Void) {
        guard !loading else {
            completion([])
            return
        }
        loading = true
        ref?.queryEnding(atValue: timestamp)
            .queryLimited(toLast: querySize)
            .queryOrdered(byChild: Child.timestamp)
            .observeSingleEvent(of: .value) { [weak self] data in
                var convos = data.asConvosArray(proxyKey: proxyKey)
                guard convos.count > 1 else {
                    completion([])
                    return
                }
                convos.removeLast(1)
                completion(convos.reversed())
                self?.loading = false
        }
    }

    deinit {
        stopObserving()
    }
}
