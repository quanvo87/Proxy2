import FirebaseDatabase
import UIKit

class MessagesSentObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var controller: MessagesSentObserving?
    private(set) var handle: DatabaseHandle?

    init(user: String = Shared.shared.uid, controller: MessagesSentObserving) {
        ref = DB.makeReference(Child.userInfo, user, IncrementableUserProperty.messagesSent.rawValue)
        self.controller = controller
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { [weak self] (data) in
            if let count = data.value as? UInt {
                self?.controller?.messagesSentCount = count.asStringWithCommas
                self?.controller?.reload()
//                self?.controller?.tableView.reloadData()
                
            }
        })
    }

    deinit {
        stopObserving()
    }
}

protocol MessagesSentObserving: class, TableViewReloading {
    var messagesSentCount: String { get set }
}
