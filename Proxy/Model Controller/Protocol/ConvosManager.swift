import FirebaseDatabase
import UIKit

class ConvosManager: ConvosManaging {
    var convos: [Convo] = [] {
        didSet {
            if convos.isEmpty {
                animator?.animateButton()
            } else {
                animator?.stopAnimatingButton()
            }
            tableView?.reloadData()
        }
    }
    let ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private let proxyKey: String?
    private let querySize: UInt
    private let uid: String
    private var loading = false
    private weak var animator: ButtonAnimating?
    private weak var tableView: UITableView?

    init(proxyKey: String?,
         querySize: UInt = Setting.querySize,
         uid: String,
         animator: ButtonAnimating?,
         tableView: UITableView?) {
        self.proxyKey = proxyKey
        self.querySize = querySize
        self.uid = uid
        self.animator = animator
        self.tableView = tableView
        ref = DB.makeReference(Child.convos, uid)
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.queryOrdered(byChild: Child.timestamp).queryLimited(toLast: querySize).observe(.value) { [weak self] (data) in
            guard let _self = self else {
                return
            }
            _self.loading = true
            _self.convos = data.toConvosArray(uid: _self.uid, proxyKey: _self.proxyKey).reversed()
            _self.loading = false
        }
    }

    func loadConvos(endingAtTimestamp timestamp: Double) {
        guard !loading else {
            return
        }
        loading = true
        ref?.queryOrdered(byChild: Child.timestamp)
            .queryEnding(atValue: timestamp)
            .queryLimited(toLast: querySize)
            .observeSingleEvent(of: .value) { [weak self] (data) in
                guard let _self = self else {
                    return
                }
                var convos = data.toConvosArray(uid: _self.uid, proxyKey: _self.proxyKey)
                guard convos.count > 1 else {
                    return
                }
                convos.removeLast(1)
                _self.convos += convos.reversed()
                _self.loading = false
        }
    }

    deinit {
        stopObserving()
    }
}
