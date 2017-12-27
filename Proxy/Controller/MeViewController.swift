import UIKit

class MeViewController: UIViewController {
    private let messagesReceivedManager = MessagesReceivedCountManager()
    private let messagesSentManager = MessagesSentCountManager()
    private let proxiesInteractedWithManager = ProxiesInteractedWithCountManager()
    private let dataSource = MeTableViewDataSource()
    private let delegate = MeTableViewDelegate()
    private let tableView = UITableView(frame: .zero, style: .grouped)

    init(uid: String, displayName: String?) {
        super.init(nibName: nil, bundle: nil)

        navigationItem.title = displayName

        messagesReceivedManager.load(uid: uid, tableView: tableView)

        messagesSentManager.load(uid: uid, tableView: tableView)

        proxiesInteractedWithManager.load(uid: uid, tableView: tableView)

        dataSource.load(messagesReceivedManager: messagesReceivedManager,
                        messagesSentManager: messagesSentManager,
                        proxiesInteractedWithManager: proxiesInteractedWithManager)

        delegate.load(controller: self)

        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.meTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.meTableViewCell)
        tableView.rowHeight = 44
        view.addSubview(tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
