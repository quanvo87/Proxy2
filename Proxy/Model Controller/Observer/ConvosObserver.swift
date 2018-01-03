import FirebaseDatabase

class ConvosObserver: ReferenceObserving {
    private (set) var ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private weak var manager: ConvosManaging?
    private var loading = true
    private var proxyKey: String?

    func observe(convosOwner: String, proxyKey: String?, manager: ConvosManaging, querySize: UInt = Setting.querySize) {
        stopObserving()
        self.proxyKey = proxyKey
        self.manager = manager
        ref = DB.makeReference(Child.convos, convosOwner)
        handle = ref?.queryOrdered(byChild: Child.timestamp).queryLimited(toLast: querySize).observe(.value, with: { [weak self] (data) in
            self?.loading = true

            // todo: clean up
//            var convos = [Convo]()
//
//            for child in data.children {
//                guard let data = child as? DataSnapshot else {
//                    continue
//                }
//                if let convo = Convo(data) {
//                    convos.append(convo)
//                    continue
//                }
//                DB.get(Child.convos, convosOwner, data.key) { (data) in
//                    guard let data = data else {
//                        return
//                    }
//                    if let convo = Convo(data) {
//                        convos.append(convo)
//                    } else {
//                        DB.delete(Child.convos, convosOwner, data.key) { (_) in }
//                    }
//                }
//            }

            self?.manager?.convos = data.toConvosArray(proxyKey).reversed()
            self?.loading = false
        })

    }

    func getConvos(endingAtTimestamp timestamp: Double, querySize: UInt) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrdered(byChild: Child.timestamp).queryEnding(atValue: timestamp).queryLimited(toLast: querySize).observeSingleEvent(of: .value, with: { [weak self] (data) in
            var convos = data.toConvosArray(self?.proxyKey)
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
