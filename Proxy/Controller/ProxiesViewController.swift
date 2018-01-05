import UIKit

class ProxiesViewController: UIViewController, MakeNewMessageDelegate {
    var newConvo: Convo?

    private let itemsToDeleteManager = ItemsToDeleteManager()
    private let dataSource = ProxiesTableViewDataSource()
    private let delegate = ProxiesTableViewDelegate()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let buttonManager = ProxiesButtonManager()
    private let container: DependencyContaining

    init(uid: String, container: DependencyContaining) {
        self.container = container
        
        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "My Proxies"

        buttonManager.load(container: container, uid: uid, controller: self, itemsToDeleteManager: itemsToDeleteManager, tableView: tableView)
        
        container.proxiesManager.load(uid: uid, controller: self, manager: buttonManager, tableView: tableView)

        dataSource.load(accessoryType: .disclosureIndicator, container: container)

        delegate.load(manager: itemsToDeleteManager, controller: self, container: container)

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
            navigationController?.showConvoViewController(convo: newConvo, container: container)
            self.newConvo = nil
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        // todo: else stop animating
        if container.proxiesManager.proxies.isEmpty {
            buttonManager.animateButton(buttonManager.makeNewProxyButton, loop: true)
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
