import UIKit

class MessagesViewController: UIViewController, MakeNewMessageDelegate {
    private let buttonManager = MessagesButtonManager()
    private let convosManager = ConvosManager()
    private let dataSource = MessagesTableViewDataSource()
    private let delegate = MessagesTableViewDelegate()
    private let itemsToDeleteManager = ItemsToDeleteManager()
    private let unreadCountManager = MessagesUnreadCountManager()
    private let tableView = UITableView()
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
        buttonManager.load(controller: self, itemsToDeleteManager: itemsToDeleteManager, tableView: tableView, uid: uid)
        convosManager.load(convosOwner: uid, tableView: tableView)
        dataSource.load(manager: convosManager, tableView: tableView)
        delegate.load(controller: self, convosManager: convosManager, itemsToDeleteManager: itemsToDeleteManager, tableView: tableView)
        navigationItem.title = "Messages"
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.rowHeight = 80
        tableView.separatorStyle = .none
        unreadCountManager.load(uid: uid, controller: self)
        view.addSubview(tableView)
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
