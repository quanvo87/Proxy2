import UIKit

class ConvosViewController: UIViewController, MakeNewMessageDelegate {
    var newConvo: Convo?
    private let buttonManager = ConvosButtonManager()
    private let dataSource = ConvosTableViewDataSource()
    private let delegate = ConvosTableViewDelegate()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private lazy var convosManager = ConvosManager(proxyKey: nil,
                                                   uid: uid,
                                                   animator: buttonManager,
                                                   tableView: tableView)

    init(uid: String,
         presenceManager: PresenceManaging,
         proxiesManager: ProxiesManaging,
         unreadMessagesManager: UnreadMessagesManaging) {
        self.uid = uid
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager
        
        super.init(nibName: nil, bundle: nil)

        buttonManager.load(uid: uid, controller: self, delegate: self, manager: proxiesManager)

        dataSource.load(convosManager)

        delegate.load(controller: self, convosManager: convosManager, presenceManager: presenceManager, proxiesManager: proxiesManager, unreadMessagesManager: unreadMessagesManager)

        navigationItem.title = "Messages"

        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.convosTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.convosTableViewCell)
        tableView.rowHeight = 80
        tableView.sectionHeaderHeight = 0

        unreadMessagesManager.load(uid: uid, controller: self, presenceManager: presenceManager, proxiesManager: proxiesManager)

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if convosManager.convos.isEmpty {
            buttonManager.animateButton()
        }
        guard
            let newConvo = newConvo,
            let presenceManager = presenceManager,
            let proxiesManager = proxiesManager,
            let unreadMessagesManager = unreadMessagesManager else {
                return
        }
        navigationController?.showConvoViewController(convo: newConvo, presenceManager: presenceManager, proxiesManager: proxiesManager, unreadMessagesManager: unreadMessagesManager)
        self.newConvo = nil
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
