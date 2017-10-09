import UIKit

class ProxiesTableViewController: UITableViewController, MakeNewMessageDelegate {
    let buttonManager = ProxiesButtonManager()
    let dataSource = ProxiesTableViewDataSource()
    let delegate = ProxiesTableViewDelegate()
    let proxiesManager = ProxiesManager()
    var newConvo: Convo?

    override func viewDidLoad() {
        super.viewDidLoad()
        buttonManager.load(self)
        navigationItem.title = "Proxies"
        proxiesManager.load(tableView)
        setupDataSource()
        setupDelegate()
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

private extension ProxiesTableViewController {
    func setupDataSource() {
        dataSource.manager = proxiesManager
        dataSource.showDisclosureIndicator = true
        tableView.dataSource = dataSource
    }

    func setupDelegate() {
        delegate.controller = self
        delegate.itemsToDeleteManager = buttonManager.itemsToDeleteManager
        delegate.proxiesManager = proxiesManager
        tableView.delegate = delegate
    }
}
