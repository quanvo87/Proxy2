import FirebaseDatabase
import UIKit

class MessagesReceivedObserver: ReferenceObserving {
    let ref: DatabaseReference?
    private weak var controller: MessagesReceivedObserving?
    private(set) var handle: DatabaseHandle?

    init(user: String = Shared.shared.uid, controller: MessagesReceivedObserving) {
        ref = DB.makeReference(Child.userInfo, user, IncrementableUserProperty.messagesReceived.rawValue)
        self.controller = controller
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value, with: { [weak self] (data) in
            if let count = data.value as? UInt {
                self?.controller?.messagesReceivedCount = count.asStringWithCommas
//                self?.controller?.reload()
//                self?.controller?.tableView.reloadData()
            }
        })
    }

    deinit {
        stopObserving()
    }
}

protocol MessagesReceivedObserving: class, TableViewReloading {
    var messagesReceivedCount: String { get set }
}
