import UIKit

class SenderPickerTableViewController: UITableViewController {
    private var dataSource: ProxiesTableViewDataSource?
    private var delegate: SenderPickerTableViewDelegate?
    weak var senderPickerDelegate: SenderPickerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = ProxiesTableViewDataSource(tableView)
        delegate = SenderPickerTableViewDelegate(delegate: senderPickerDelegate, tableViewController: self)
        navigationItem.title = "Pick A Sender"
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
}

protocol SenderPickerDelegate: class {
    var sender: Proxy? { get set }
}
