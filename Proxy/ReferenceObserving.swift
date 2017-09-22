import FirebaseDatabase
import UIKit

protocol ReferenceObserving {
    var ref: DatabaseReference? { get }
    var handle: DatabaseHandle? { get }
}

extension ReferenceObserving {
    func stopObserving() {
        if let handle = handle {
            ref?.removeObserver(withHandle: handle)
        }
    }
}

protocol TableViewReloading {
    var tableView: UITableView! { get }
}

extension TableViewReloading {
    func reload() {
        tableView.reloadData()
    }
}
