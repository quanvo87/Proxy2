import FirebaseDatabase
import UIKit

class ConvosObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var controller: ConvosObserving?
    private(set) var handle: DatabaseHandle?

    init(owner: String, controller: ConvosObserving) {
        ref = DB.makeReference(Child.convos, owner)
        self.controller = controller
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.queryOrdered(byChild: Child.timestamp).observe(.value, with: { [weak self] (data) in
            self?.controller?.convos = data.toConvosArray(filtered: true).reversed()
            self?.controller?.tableView?.reloadData()
        })
    }

    deinit {
        stopObserving()
    }
}

protocol ConvosObserving: class, TableViewOwning {
    var convos: [Convo] { get set }
}
