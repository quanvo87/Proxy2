import UIKit

class SenderPickerTableViewController: UITableViewController, ProxiesObserving {
    private var dataSource: ProxiesTableViewDataSource?
    private var delegate: SenderPickerTableViewDelegate?
    private var proxiesObserver: ProxiesObserver?
    weak var senderPickerDelegate: SenderPickerDelegate?
    var proxies = [Proxy]()

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = ProxiesTableViewDataSource(self)
        delegate = SenderPickerTableViewDelegate(delegate: senderPickerDelegate, controller: self)
        navigationItem.title = "Pick A Sender"
        proxiesObserver = ProxiesObserver(self)
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
}

protocol SenderPickerDelegate: class {
    var sender: Proxy? { get set }
}
