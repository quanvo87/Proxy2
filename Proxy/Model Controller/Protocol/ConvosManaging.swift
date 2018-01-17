import FirebaseDatabase
import UIKit

protocol ConvosManaging: ReferenceObserving {
    var convos: [Convo] { get }
    func loadConvos(endingAtTimestamp timestamp: Double)
}

class ConvosManager: ConvosManaging {
    private (set) var convos = [Convo]() {
        didSet {
            if convos.isEmpty {
                manager?.animateButton()
            } else {
                manager?.stopAnimatingButton()
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
    private weak var manager: ButtonManaging?
    private weak var tableView: UITableView?

    init(proxyKey: String?,
         querySize: UInt = Setting.querySize,
         uid: String,
         manager: ButtonManaging?,
         tableView: UITableView?) {
        self.proxyKey = proxyKey
        self.querySize = querySize
        self.uid = uid
        self.manager = manager
        self.tableView = tableView
        ref = DB.makeReference(Child.convos, uid)
        handle = ref?
            .queryOrdered(byChild: Child.timestamp)
            .queryLimited(toLast: querySize)
            .observe(.value) { [weak self] (data) in
                guard let _self = self else {
                    return
                }
                self?.loading = true
                self?.convos = data.toConvosArray(uid: _self.uid, proxyKey: _self.proxyKey).reversed()
                self?.loading = false
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
                self?.convos += convos.reversed()
                self?.loading = false
        }
    }

    deinit {
        stopObserving()
    }
}
