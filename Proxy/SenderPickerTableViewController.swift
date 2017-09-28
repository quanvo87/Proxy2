import UIKit

class SenderPickerTableViewController: UITableViewController {
    let dataSource = ProxiesTableViewDataSource()
    let delegate = SenderPickerTableViewDelegate()
    let manager = ProxiesManager()
    let reloader = TableViewReloader()
    weak var senderPickerDelegate: SenderPickerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource.load(manager: manager, tableView: tableView, showDisclosureIndicator: false)
        delegate.load(self)
        manager.load(reloader)
        navigationItem.title = "Pick A Sender"
        reloader.tableView = tableView
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
}

protocol SenderPickerDelegate: class {
    var sender: Proxy? { get set }
}
