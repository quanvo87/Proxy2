import UIKit

class SenderPickerTableViewController: UITableViewController {
    let dataSource = ProxiesTableViewDataSource()
    let delegate = SenderPickerTableViewDelegate()
    let manager = ProxiesManager()
    weak var senderPickerDelegate: SenderPickerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        delegate.load(self)
        manager.load(tableView)
        navigationItem.title = "Pick A Sender"
        setupDataSource()
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
}

private extension SenderPickerTableViewController {
    func setupDataSource() {
        dataSource.manager = manager
        dataSource.showDisclosureIndicator = false
        tableView.dataSource = dataSource
    }

    func setupDelegate() {
        delegate.controller = self
        tableView.delegate = delegate
    }
}

protocol SenderPickerDelegate: class {
    var sender: Proxy? { get set }
}
