import UIKit

class SenderPickerTableViewController: UITableViewController {
    private var dataSource: ProxiesTableViewDataSource?
    private var delegate: SenderPickerTableViewDelegate?

    private weak var senderPickerDelegate: SenderPickerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource = ProxiesTableViewDataSource(tableView)
        dataSource?.proxiesObserver?.observe()

        delegate = SenderPickerTableViewDelegate(delegate: senderPickerDelegate, tableViewController: self)

        navigationItem.title = "Pick A Sender"

        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }

    func setSenderPickerDelegate(to delegate: SenderPickerDelegate) {
        self.senderPickerDelegate = delegate
    }
}

protocol SenderPickerDelegate: class {
    func setSender(to proxy: Proxy)
}
