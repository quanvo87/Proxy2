import UIKit

class ProxiesTableViewController: UITableViewController, MakeNewMessageDelegate {
    private let buttonManager = ProxiesButtonManager()
    private let dataSource = ProxiesTableViewDataSource()
    private let delegate = ProxiesTableViewDelegate()
    private let itemsToDeleteManager = ItemsToDeleteManager()
    private let proxiesManager = ProxiesManager()
    private let uid: String
    var newConvo: Convo?

    init(_ uid: String) {
        self.uid = uid
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buttonManager.load(controller: self, itemsToDeleteManager: itemsToDeleteManager, proxiesManager: proxiesManager, uid: uid)
        dataSource.load(manager: proxiesManager, showDisclosureIndicator: true, tableView: tableView)
        delegate.load(controller: self, itemsToDeleteManager: itemsToDeleteManager, proxiesManager: proxiesManager)
        proxiesManager.load(uid: uid, tableView: tableView)
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
        title = "Proxies"
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
