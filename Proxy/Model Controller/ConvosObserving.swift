import FirebaseDatabase
import FirebaseHelper
import UIKit

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

    required init(querySize: UInt = Setting.querySize) {
        self.querySize = querySize
    }

    func observe(convosOwnerId: String, proxyKey: String?, completion: @escaping ([Convo]) -> Void) {
        stopObserving()
        ref = try? FirebaseHelper.main.makeReference(Child.convos, convosOwnerId)
        handle = ref?
            .queryLimited(toLast: querySize)
            .queryOrdered(byChild: Child.timestamp)
            .observe(.value) { [weak self] data in
                self?.loading = true
                completion(data.toConvosArray(proxyKey: proxyKey).reversed())
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
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        ref?.queryEnding(atValue: timestamp)
            .queryLimited(toLast: querySize)
            .queryOrdered(byChild: Child.timestamp)
            .observeSingleEvent(of: .value) { [weak self] data in
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                var convos = data.toConvosArray(proxyKey: proxyKey)
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
