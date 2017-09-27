import UIKit

class ProxiesTableViewController: UITableViewController, MakeNewMessageDelegate {
    let dataSource = ProxiesTableViewDataSource()
    let delegate = ProxiesTableViewDelegate()
    let proxiesManager = ProxiesManager()
    let reloader = TableViewReloader()
    var buttonManager: ProxiesButtonManager?
    var newConvo: Convo?

    override func viewDidLoad() {
        super.viewDidLoad()
        buttonManager = ProxiesButtonManager(self)
        dataSource.load(manager: proxiesManager, tableView: tableView)
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
        guard
            let convoVC = storyboard?.instantiateViewController(withIdentifier: Identifier.convoViewController) as? ConvoViewController,
            let newConvo = newConvo else {
                return
        }
        convoVC.convo = newConvo
        self.newConvo = nil
        navigationController?.pushViewController(convoVC, animated: true)
    }

    func scrollToTop() {
        guard tableView.numberOfRows(inSection: 0) > 0 else { return }
        tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
    }
}
