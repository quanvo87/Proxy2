import FirebaseDatabase
import MessageKit

class ConvoManager: ConvoManaging {
    var convo: Convo {
        didSet {
            for listener in listeners.allObjects {
                switch listener {
                case let controller as UIViewController:
                    controller.navigationItem.title = convo.receiverDisplayName
                case let collectionView as MessagesCollectionView:
                    collectionView.reloadDataAndKeepOffset()
                case let tableView as UITableView:
                    tableView.reloadData()
                default:
                    break
                }
            }
        }
    }
    let listeners = NSHashTable<AnyObject>(options: .weakMemory)
    let ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?

    init(_ convo: Convo) {
        self.convo = convo
        ref = DB.makeReference(Child.convos, convo.senderId, convo.key)
        observe()
    }

    func observe() {
        stopObserving()
        handle = ref?.observe(.value) { [weak self] (data) in
            guard let _self = self else {
                return
            }
            guard let convo = Convo(data) else {
                DB.checkKeyExists(Child.convos, _self.convo.senderId, _self.convo.key) { (exists) in
                    if !exists {
                        _self.updateClosers()
                    }
                }
                return
            }
            _self.convo = convo
        }
    }

    deinit {
        stopObserving()
    }
}

private extension ConvoManager {
    func updateClosers() {
        for listener in listeners.allObjects {
            guard let closer = listener as? Closing else {
                continue
            }
            closer.shouldClose = true
        }
    }
}
