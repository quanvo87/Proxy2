import UIKit

class ProxiesViewController: UIViewController, MakeNewMessageDelegate {
    private let buttonManager = ProxiesButtonManager()
    private let dataSource = ProxiesTableViewDataSource()
    private let delegate = ProxiesTableViewDelegate()
    private let itemsToDeleteManager = ItemsToDeleteManager()
    private let proxiesManager = ProxiesManager()
    private let tableView = UITableView()
    private let uid: String
    var newConvo: Convo?

    init(_ uid: String) {
        self.uid = uid
        
        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "Proxies"

        dataSource.load(manager: proxiesManager, showDisclosureIndicator: true)
        delegate.load(controller: self, itemsToDeleteManager: itemsToDeleteManager, proxiesManager: proxiesManager)

        buttonManager.load(controller: self, itemsToDeleteManager: itemsToDeleteManager, proxiesManager: proxiesManager, tableView: tableView, uid: uid)
        proxiesManager.load(uid: uid, tableView: tableView)

        tableView.allowsMultipleSelectionDuringEditing = true
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Name.proxiesTableViewCell, bundle: nil), forCellReuseIdentifier: Name.proxiesTableViewCell)
        tableView.rowHeight = 60
        tableView.separatorStyle = .none

        view.addSubview(tableView)
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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
