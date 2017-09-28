import UIKit

class ProxiesTableViewController: UITableViewController, MakeNewMessageDelegate {
    let buttonManager = ProxiesButtonManager()
    let dataSource = ProxiesTableViewDataSource()
    let delegate = ProxiesTableViewDelegate()
    let proxiesManager = ProxiesManager()
    let reloader = TableViewReloader()
    var newConvo: Convo?

    override func viewDidLoad() {
        super.viewDidLoad()
        buttonManager.load(self)
        dataSource.load(manager: proxiesManager, tableView: tableView, showDisclosureIndicator: true)
        delegate.load(self)
        navigationItem.title = "Proxies"
        proxiesManager.load(reloader)
        reloader.tableView = tableView
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if let newConvo = newConvo {
            goToConvoVC(newConvo)
            self.newConvo = nil
        }
    }

    func scrollToTop() {
        guard tableView.numberOfRows(inSection: 0) > 0 else { return }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}
