import UIKit

class ConvoDetailViewController: UIViewController, Closing {
    var shouldClose: Bool = false
    private let convoManager = ConvoManager()
    private let dataSource = ConvoDetailTableViewDataSource()
    private let delegate = ConvoDetailTableViewDelegate()
    private let proxyManager = ProxyManager()
    private let tableView = UITableView(frame: .zero, style: .grouped)

    init(convo: Convo,
         presenceManager: PresenceManaging,
         proxiesManager: ProxiesManaging,
         unreadMessagesManager: UnreadMessagesManaging) {
        super.init(nibName: nil, bundle: nil)

        convoManager.load(uid: convo.senderId, key: convo.key, tableView: tableView, closer: self)

        proxyManager.load(uid: convo.senderId, key: convo.senderProxyKey, tableView: tableView, closer: self)

        dataSource.load(controller: self, convoManager: convoManager, proxyManager: proxyManager)

        delegate.load(controller: self, convoManager: convoManager, presenceManager: presenceManager, proxiesManager: proxiesManager, proxyManager: proxyManager, unreadMessagesManager: unreadMessagesManager)

        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.delaysContentTouches = false
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.convoDetailReceiverProxyTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.convoDetailReceiverProxyTableViewCell)
        tableView.register(UINib(nibName: Identifier.convoDetailSenderProxyTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.convoDetailSenderProxyTableViewCell)
        tableView.setDelaysContentTouchesForScrollViews()

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if shouldClose {
            _ = navigationController?.popViewController(animated: false)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
