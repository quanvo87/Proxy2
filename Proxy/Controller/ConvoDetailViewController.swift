import UIKit

class ConvoDetailViewController: UIViewController, Closing {
    var shouldClose: Bool = false
    private let convo: Convo
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private weak var manager: ConvoManaging?
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private lazy var dataSource = ConvoDetailTableViewDataSource(controller: self,
                                                                 convoManager: manager,
                                                                 proxyManager: proxyManager)
    private lazy var delegate = ConvoDetailTableViewDelegate(controller: self,
                                                             convoManager: manager,
                                                             presenceManager: presenceManager,
                                                             proxiesManager: proxiesManager,
                                                             proxyManager: proxyManager,
                                                             unreadMessagesManager: unreadMessagesManager)
    private lazy var proxyManager = ProxyManager(closer: self,
                                                 key: convo.senderProxyKey,
                                                 tableView: tableView,
                                                 uid: convo.senderId)

    init(convo: Convo,
         manager: ConvoManaging?,
         presenceManager: PresenceManaging?,
         proxiesManager: ProxiesManaging?,
         unreadMessagesManager: UnreadMessagesManaging?) {
        self.convo = convo
        self.manager = manager
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        manager?.addCloser(self)
        manager?.addTableView(tableView)

        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.delaysContentTouches = false
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.convoDetailReceiverProxyTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.convoDetailReceiverProxyTableViewCell)
        tableView.register(UINib(nibName: Identifier.convoDetailSenderProxyTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.convoDetailSenderProxyTableViewCell)
        tableView.setDelaysContentTouchesForScrollViews()

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldClose {
            _ = navigationController?.popViewController(animated: false)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
