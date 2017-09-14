import FirebaseDatabase
import UIKit

class ConvosObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private(set) var convos = [Convo]()
    private(set) var handle: DatabaseHandle?
    private weak var tableView: UITableView?

    init(owner: String, tableView: UITableView) {
        ref = DB.makeReference(Child.convos, owner)
        self.tableView = tableView
    }

    func observe() {
        stopObserving()
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self] (data) in
            self?.convos = data.toConvosArray(filtered: true).reversed()
            self?.tableView?.reloadData()
        })
    }

    deinit {
        stopObserving()
    }
}
