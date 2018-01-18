import FirebaseDatabase
import MessageKit

protocol ConvoManaging: ReferenceObserving {
    var convo: Convo { get }
    func addCloser(_ closer: Closing)
    func addController(_ controller: UIViewController)
    func addCollectionView(_ collectionView: MessagesCollectionView)
    func addTableView(_ tableView: UITableView)
}

class ConvoManager: ConvoManaging {
    private (set) var convo: Convo {
        didSet {
            for controller in controllers.allObjects {
                guard let controller = controller as? UIViewController else {
                    continue
                }
                controller.navigationItem.title = convo.receiverDisplayName
            }
            for collectionView in collectionViews.allObjects {
                guard let collectionView = collectionView as? MessagesCollectionView else {
                    continue
                }
                collectionView.reloadDataAndKeepOffset()
            }
            for tableView in tableViews.allObjects {
                guard let tableView = tableView as? UITableView else {
                    continue
                }
                tableView.reloadData()
            }
        }
    }
    let ref: DatabaseReference?
    private (set) var handle: DatabaseHandle?
    private let closers = NSHashTable<AnyObject>(options: .weakMemory)
    private let controllers = NSHashTable<AnyObject>(options: .weakMemory)
    private let collectionViews = NSHashTable<AnyObject>(options: .weakMemory)
    private let tableViews = NSHashTable<AnyObject>(options: .weakMemory)

    init(_ convo: Convo) {
        self.convo = convo
        ref = DB.makeReference(Child.convos, convo.senderId, convo.key)
        handle = ref?.observe(.value) { [weak self] (data) in
            guard let _self = self else {
                return
            }
            guard let convo = Convo(data) else {
                DB.getConvo(uid: _self.convo.senderId, key: _self.convo.key) { [weak self] (convo) in
                    if convo == nil {
                        self?.updateClosers()
                    }
                }
                return
            }
            self?.convo = convo
        }
    }

    func addCloser(_ closer: Closing) {
        closers.add(closer)
    }

    func addController(_ controller: UIViewController) {
        controllers.add(controller)
    }

    func addCollectionView(_ collectionView: MessagesCollectionView) {
        collectionViews.add(collectionView)
    }

    func addTableView(_ tableView: UITableView) {
        tableViews.add(tableView)
    }

    deinit {
        stopObserving()
    }
}

private extension ConvoManager {
    func updateClosers() {
        for closer in closers.allObjects {
            guard let closer = closer as? Closing else {
                continue
            }
            closer.shouldClose = true
        }
    }
}
