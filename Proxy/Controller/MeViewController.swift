import UIKit

class MeViewController: UIViewController {
    private let dataSource = MeTableViewDataSource()
    private let delegate = MeTableViewDelegate()
    private let messagesReceivedManager = MessagesReceivedManager()
    private let messagesSentManager = MessagesSentManager()
    private let proxiesInteractedWithManager = ProxiesInteractedWithManager()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let displayName: String
    private let uid: String

    init(displayName: String, uid: String) {
        self.displayName = displayName
        self.uid = uid
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource.load(messagesReceivedManager: messagesReceivedManager,
                        messagesSentManager: messagesSentManager,
                        proxiesInteractedWithManager: proxiesInteractedWithManager,
                        tableView: tableView)
        delegate.load(controller: self, tableView: tableView)
        messagesReceivedManager.load(uid: uid, tableView: tableView)
        messagesSentManager.load(uid: uid, tableView: tableView)
        navigationItem.title = displayName
        proxiesInteractedWithManager.load(uid: uid, tableView: tableView)
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.rowHeight = 44
        view.addSubview(tableView)
    }
}
