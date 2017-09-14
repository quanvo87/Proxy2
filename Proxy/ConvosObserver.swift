import FirebaseDatabase
import UIKit

class ConvosObserver: ReferenceObserving {
    private(set) var convos = [Convo]()
    private(set) var handle: DatabaseHandle?
    private(set) var ref: DatabaseReference?

    func observeConvos(owner: String, tableView: UITableView) {
        stopObserving()
        ref = DB.makeReference(Child.convos, owner)
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self, weak tableView = tableView] (data) in
            self?.convos = data.toConvosArray(filtered: true).reversed()
            tableView?.reloadData()
        })
    }

    deinit {
        stopObserving()
    }
}
