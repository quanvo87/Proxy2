import FirebaseDatabase
import UIKit

class ProxiesInteractedWithObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var controller: ProxiesInteractedWithObserving?
    private(set) var handle: DatabaseHandle?

    init(user: String = Shared.shared.uid, controller: ProxiesInteractedWithObserving) {
        ref = DB.makeReference(Child.userInfo, user, IncrementableUserProperty.proxiesInteractedWith.rawValue)
        self.controller = controller
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { [weak self] (data) in
            if let count = data.value as? UInt {
                self?.controller?.proxiesInteractedWithCount = count.asStringWithCommas
                self?.controller?.tableView.reloadData()
            }
        })
    }

    deinit {
        stopObserving()
    }
}

protocol ProxiesInteractedWithObserving: class, TableViewOwning {
    var proxiesInteractedWithCount: String { get set }
}
