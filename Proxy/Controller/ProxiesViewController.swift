import UIKit

class ProxiesViewController: UIViewController, MakeNewMessageDelegate {
    var newConvo: Convo?
    private let itemsToDeleteManager = ItemsToDeleteManager()
    private let dataSource = ProxiesTableViewDataSource()
    private let delegate = ProxiesTableViewDelegate()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let buttonManager = ProxiesButtonManager()
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?

    init(uid: String,
         presenceManager: PresenceManaging,
         proxiesManager: ProxiesManaging,
         unreadMessagesManager: UnreadMessagesManaging) {
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager
        
        super.init(nibName: nil, bundle: nil)

        buttonManager.load(uid: uid, controller: self, delegate: self, itemsToDeleteManager: itemsToDeleteManager, proxiesManager: proxiesManager, tableView: tableView)

        dataSource.load(accessoryType: .disclosureIndicator, manager: proxiesManager)

        delegate.load(controller: self, itemsToDeleteManager: itemsToDeleteManager, presenceManager: presenceManager, proxiesManager: proxiesManager, unreadMessagesManager: unreadMessagesManager)

        navigationItem.title = "My Proxies"

        proxiesManager.load(uid: uid, controller: self, manager: buttonManager, tableView: tableView)

        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.proxiesTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.proxiesTableViewCell)
        tableView.rowHeight = 60
        tableView.sectionHeaderHeight = 0

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        if proxiesManager?.proxies.isEmpty ?? false {
            buttonManager.animate(buttonManager.makeNewProxyButton, loop: true)
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
