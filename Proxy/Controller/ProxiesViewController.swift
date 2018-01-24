import UIKit

class ProxiesViewController: UIViewController, ItemsToDeleteManaging, NewConvoManaging, ProxiesManaging {
    var proxies = [Proxy]() {
        didSet {
            navigationController?.title = "My Proxies\(proxies.count.asStringWithParens)"
            navigationController?.tabBarController?.tabBar.items?[1].title = "Proxies\(proxies.count.asStringWithParens)"
            // todo: animate button
            tableView.reloadData()
        }
    }

    var itemsToDelete: [String: Any] = [:]
    var newConvo: Convo?
    private let proxiesObserver: ProxiesObserving
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private weak var presenceManager: PresenceManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private lazy var buttonManager = ProxiesButtonManager(uid: uid,
                                                          controller: self,
                                                          itemsToDeleteManager: self,
                                                          newConvoManager: self,
                                                          proxiesManager: nil,
                                                          tableView: tableView)
    private lazy var dataSource = ProxiesTableViewDataSource(accessoryType: .disclosureIndicator,
                                                             manager: nil)
    private lazy var delegate = ProxiesTableViewDelegate(controller: self,
                                                         itemsToDeleteManager: self,
                                                         presenceManager: presenceManager,
                                                         proxiesManager: nil,
                                                         unreadMessagesManager: unreadMessagesManager)

    init(proxiesObserver: ProxiesObserving = ProxiesObserver(),
         uid: String,
         presenceManager: PresenceManaging?,
         unreadMessagesManager: UnreadMessagesManaging?) {
        self.proxiesObserver = proxiesObserver
        self.uid = uid
        self.presenceManager = presenceManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "My Proxies"

        proxiesObserver.load(manager: self, uid: uid)

        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.proxiesTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.proxiesTableViewCell)
        tableView.rowHeight = 60
        tableView.sectionHeaderHeight = 0

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if proxies.isEmpty {
            buttonManager.animateButton()
        }
        if let newConvo = newConvo {
            showConvoController(convo: newConvo,
                                presenceManager: presenceManager,
                                unreadMessagesManager: unreadMessagesManager)
            self.newConvo = nil
        }
    }

    func scrollToTop() {
        guard tableView.numberOfRows(inSection: 0) > 0 else {
            return
        }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
