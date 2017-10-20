import UIKit

class MessagesTableViewController: UITableViewController, MakeNewMessageDelegate {
    private let buttonManager = MessagesButtonManager()
    private let convosManager = ConvosManager()
    private let dataSource = MessagesTableViewDataSource()
    private let delegate = MessagesTableViewDelegate()
    private let itemsToDeleteManager = ItemsToDeleteManager()
    private let unreadCountManager = MessagesUnreadCountManager()
    private let uid: String
    var newConvo: Convo?

    init(_ uid: String) {
        self.uid = uid
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        buttonManager.load(controller: self, itemsToDeleteManager: itemsToDeleteManager, uid: uid)
        convosManager.load(convosOwner: uid, tableView: tableView)
//        dataSource.load(manager: convosManager, tableView: tableView)
        delegate.load(controller: self, convosManager: convosManager, itemsToDeleteManager: itemsToDeleteManager)
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
        title = "Messages"
        unreadCountManager.load(uid: uid, controller: self)
        Shared.shared.queue.async {
            DBProxy.fixConvoCounts(uid: self.uid) { _ in }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let newConvo = newConvo {
            showConvoController(newConvo)
            self.newConvo = nil
        }
    }
}
