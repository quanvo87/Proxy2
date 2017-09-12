import UIKit

class ProxiesTableViewController: UITableViewController {
    private var buttonManager = ButtonManager()
    private var dataSource: ProxiesTableViewDataSource?
    private var delegate: ProxiesTableViewDelegate?
    private var newConvo: Convo?

    override func viewDidLoad() {
        super.viewDidLoad()

        buttonManager.makeButtons(self)

        dataSource = ProxiesTableViewDataSource(tableView)

        delegate = ProxiesTableViewDelegate(buttonManager: buttonManager, tableViewController: self)

        navigationItem.title = "Proxies"

        setDefaultButtons()
        
        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        goToNewConvo()
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

extension ProxiesTableViewController: ButtonManagerDelegate {
    func deleteSelectedItems() {
        if buttonManager.itemsToDelete.isEmpty {
            toggleEditMode()
            return
        }
        let alert = UIAlertController(title: "Delete Proxies?", message: "You will not be able to view their conversations anymore.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            self.buttonManager.disableButtons()
            self.dataSource?.proxiesObserver?.stopObserving()
            let key = AsyncWorkGroupKey()
            for (_, item) in self.buttonManager.itemsToDelete {
                if let proxy = item as? Proxy {
                    key.startWork()
                    DBProxy.deleteProxy(proxy) { _ in
                        key.finishWork()
                    }
                }
            }
            self.buttonManager.removeAllItemsToDelete()
            self.setDefaultButtons()
            self.tableView.setEditing(false, animated: true)
            key.notify {
                key.finishWorkGroup()
                self.buttonManager.enableButtons()
                self.dataSource?.proxiesObserver?.observe()
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func goToMakeNewMessageVC() {
        guard let makeNewMessageVC = self.storyboard?.instantiateViewController(withIdentifier: Identifier.makeNewMessageViewController) as? MakeNewMessageViewController else { return }
        makeNewMessageVC.setDelegate(to: self)
        let navigationController = UINavigationController(rootViewController: makeNewMessageVC)
        present(navigationController, animated: true)
    }

    func makeNewProxy() {
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

    func setDefaultButtons() {
        navigationItem.leftBarButtonItem = buttonManager.deleteButton
        navigationItem.rightBarButtonItems = [buttonManager.makeNewMessageButton, buttonManager.makeNewProxyButton]
    }

    func setEditModeButtons() {
        navigationItem.leftBarButtonItem = buttonManager.cancelButton
        navigationItem.rightBarButtonItems = [buttonManager.confirmButton]
    }

    func toggleEditMode() {
        tableView.setEditing(!tableView.isEditing, animated: true)
        if tableView.isEditing {
            setEditModeButtons()
        } else {
            setDefaultButtons()
            buttonManager.removeAllItemsToDelete()
        }
    }
}

extension ProxiesTableViewController: MakeNewMessageDelegate {
    func setNewConvo(to convo: Convo) {
        newConvo = convo
    }
}
