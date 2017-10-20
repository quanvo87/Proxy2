import UIKit

class SenderPickerTableViewController: UITableViewController {
    private let dataSource = ProxiesTableViewDataSource()
    private let delegate = SenderPickerTableViewDelegate()
    private let manager = ProxiesManager()
    weak var senderPickerDelegate: SenderPickerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Pick A Sender"
        dataSource.load(manager: manager, showDisclosureIndicator: false)
        delegate.load(controller: self, delegate: senderPickerDelegate, manager: manager)
        manager.load(uid: Shared.shared.uid, tableView: tableView)
        tableView.dataSource = dataSource
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
}

protocol SenderPickerDelegate: class {
    var sender: Proxy? { get set }
}
