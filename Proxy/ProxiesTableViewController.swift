import UIKit

class ProxiesTableViewController: UITableViewController, ButtonManaging, MakeNewMessageDelegate {
    var cancelButton = UIBarButtonItem()
    var confirmButton = UIBarButtonItem()
    var deleteButton = UIBarButtonItem()
    var makeNewMessageButton = UIBarButtonItem()
    var makeNewProxyButton = UIBarButtonItem()

    private var dataSource: ProxiesTableViewDataSource?
    private var delegate: ProxiesTableViewDelegate?
    var itemsToDelete = [String : Any]()
    var newConvo: Convo?

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = ProxiesTableViewDataSource(tableView)
        dataSource?.observe()
        delegate = ProxiesTableViewDelegate(self)
        makeButtons()
        navigationItem.title = "Proxies"
        setDefaultButtons()
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        goToNewConvo()
        dataSource?.observe()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        dataSource?.stopObserving()
    }

    func goToNewConvo() {
        guard
            let newConvo = newConvo,
            let convoVC = storyboard?.instantiateViewController(withIdentifier: Identifier.convoViewController) as? ConvoViewController else {
                return
        }
        convoVC.convo = newConvo
        self.newConvo = nil
        navigationController?.pushViewController(convoVC, animated: true)
    }

    func scrollToTop() {
        if tableView.numberOfRows(inSection: 0) > 0 {
            tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .top, animated: true)
        }
    }
}

extension ProxiesTableViewController {
    func _deleteSelectedItems() {
        if itemsToDelete.isEmpty {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Delete Proxies?", message: "You will not be able to view their conversations anymore.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.disableButtons()
            self.dataSource?.stopObserving()
            let key = AsyncWorkGroupKey()
            for (_, item) in self.itemsToDelete {
                guard let proxy = item as? Proxy else { return }
                key.startWork()
                DBProxy.deleteProxy(proxy) { _ in
                    key.finishWork()
                }
            }
            self.itemsToDelete.removeAll()
            self.setDefaultButtons()
            self.tableView.setEditing(false, animated: true)
            key.notify {
                key.finishWorkGroup()
                self.enableButtons()
                self.dataSource?.observe()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func _goToMakeNewMessageVC() {
        goToMakeNewMessageVC()
    }

    func _makeNewProxy() {
        navigationItem.toggleRightBarButtonItem(atIndex: 1)
        DBProxy.makeProxy { (result) in
            self.navigationItem.toggleRightBarButtonItem(atIndex: 1)
            switch result {
            case .failure(let error):
                self.showAlert("Error Creating Proxy", message: error.description)
            case .success:
                self.scrollToTop()
            }
        }
    }

    func _toggleEditMode() {
        toggleEditMode()
    }
}
