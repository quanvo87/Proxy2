import UIKit

class SenderPickerTableViewController: UITableViewController {
    private var dataSource: ProxiesTableViewDataSource?
    private var delegate: SenderPickerTableViewDelegate?
    private var proxiesObserver: ProxiesObserver?
    weak var senderPickerDelegate: SenderPickerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = ProxiesTableViewDataSource(self)
        delegate = SenderPickerTableViewDelegate(delegate: senderPickerDelegate, controller: self)
        navigationItem.title = "Pick A Sender"
        proxiesObserver = ProxiesObserver(tableView)
        proxiesObserver?.observe()
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
}

extension SenderPickerTableViewController: ProxiesObserving {
    var proxies: [Proxy] {
        return proxiesObserver?.proxies ?? []
    }
}

protocol SenderPickerDelegate: class {
    var sender: Proxy? { get set }
}
