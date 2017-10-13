import UIKit

class ProxiesTableViewController: UITableViewController, MakeNewMessageDelegate {
    private let dataSource = ProxiesTableViewDataSource()
    private let delegate = ProxiesTableViewDelegate()
    private let buttonManager = ProxiesButtonManager()
    private let itemsToDeleteManager = ItemsToDeleteManager()
    private let proxiesManager = ProxiesManager()
    var newConvo: Convo?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Proxies"
        dataSource.load(manager: proxiesManager, showDisclosureIndicator: true, tableView: tableView)
        delegate.load(controller: self, itemsToDeleteManager: itemsToDeleteManager, proxiesManager: proxiesManager)
        buttonManager.load(controller: self, itemsToDeleteManager: itemsToDeleteManager, proxiesManager: proxiesManager)
        proxiesManager.load(uid: Shared.shared.uid, tableView: tableView)
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let newConvo = newConvo {
            showConvoController(newConvo)
            self.newConvo = nil
        }
    }

    func scrollToTop() {
        guard tableView.numberOfRows(inSection: 0) > 0 else { return }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}
