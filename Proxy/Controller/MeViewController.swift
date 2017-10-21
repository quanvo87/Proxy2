import UIKit

class MeViewController: UIViewController {
    private let dataSource = MeTableViewDataSource()
    private let delegate = MeTableViewDelegate()
    private let messagesReceivedManager = MessagesReceivedManager()
    private let messagesSentManager = MessagesSentManager()
    private let proxiesInteractedWithManager = ProxiesInteractedWithManager()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String

    init(displayName: String, uid: String) {
        self.uid = uid
        
        super.init(nibName: nil, bundle: nil)

        navigationItem.title = displayName

        dataSource.load(messagesReceivedManager: messagesReceivedManager,
                        messagesSentManager: messagesSentManager,
                        proxiesInteractedWithManager: proxiesInteractedWithManager)
        delegate.load(controller: self)

        messagesReceivedManager.load(uid: uid, tableView: tableView)
        messagesSentManager.load(uid: uid, tableView: tableView)
        proxiesInteractedWithManager.load(uid: uid, tableView: tableView)

        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Name.meTableViewCell, bundle: nil), forCellReuseIdentifier: Name.meTableViewCell)
        tableView.rowHeight = 44

        view.addSubview(tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
