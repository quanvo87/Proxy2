import UIKit

class ProxiesViewController: UIViewController, MakeNewMessageDelegate {
    var newConvo: Convo?

    private let itemsToDeleteManager = ItemsToDeleteManager()
    private let dataSource = ProxiesTableViewDataSource()
    private let delegate = ProxiesTableViewDelegate()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let buttonManager = ProxiesButtonManager()
    private weak var proxiesManager: ProxiesManager?
    private weak var unreadMessagesManager: UnreadMessagesManaging?

    init(uid: String, proxiesManager: ProxiesManager, unreadMessagesManager: UnreadMessagesManaging) {
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager
        
        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "My Proxies"

        buttonManager.load(uid: uid, proxiesManager: proxiesManager, itemsToDeleteManager: itemsToDeleteManager, tableView: tableView, proxiesViewController: self)
        
        proxiesManager.load(uid: uid, navigationItem: navigationItem, tableView: tableView)

        dataSource.load(manager: proxiesManager, accessoryType: .disclosureIndicator)

        delegate.load(proxiesManager: proxiesManager, itemsToDeleteManager: itemsToDeleteManager, unreadMessagesManager: unreadMessagesManager, controller: self)

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
        if let newConvo = newConvo {
            navigationController?.showConvoViewController(convo: newConvo, proxiesManager: proxiesManager, unreadMessagesManager: unreadMessagesManager)
            self.newConvo = nil
        }
    }

    func scrollToTop() {
        guard tableView.numberOfRows(inSection: 0) > 0 else {
            return
        }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
