import FirebaseDatabase
import FirebaseHelper
import WQNetworkActivityIndicator

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
    private var firstCallback = true
    private var loading = true

    required init(querySize: UInt = Setting.querySize) {
        self.querySize = querySize
    }

    func observe(convosOwnerId: String, proxyKey: String?, completion: @escaping ([Convo]) -> Void) {
        stopObserving()
        firstCallback = true
        ref = try? Shared.firebaseHelper.makeReference(Child.convos, convosOwnerId)
        WQNetworkActivityIndicator.shared.show()
        handle = ref?
            .queryLimited(toLast: querySize)
            .queryOrdered(byChild: Child.timestamp)
            .observe(.value) { [weak self] data in
                if let firstCallback = self?.firstCallback, firstCallback {
                    self?.firstCallback = false
                    WQNetworkActivityIndicator.shared.hide()
                }
                self?.loading = true
                completion(data.asConvosArray(proxyKey: proxyKey).reversed())
                self?.loading = false
        }
    }

    func loadConvos(endingAtTimestamp timestamp: Double,
                    proxyKey: String?,
                    completion: @escaping ([Convo]) -> Void) {
        guard !loading else {
            return
        }
        loading = true
        WQNetworkActivityIndicator.shared.show()
        ref?.queryEnding(atValue: timestamp)
            .queryLimited(toLast: querySize)
            .queryOrdered(byChild: Child.timestamp)
            .observeSingleEvent(of: .value) { [weak self] data in
                WQNetworkActivityIndicator.shared.hide()
                var convos = data.asConvosArray(proxyKey: proxyKey)
                guard convos.count > 1 else {
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
