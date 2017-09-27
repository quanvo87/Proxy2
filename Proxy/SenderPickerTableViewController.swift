import UIKit

class SenderPickerTableViewController: UITableViewController, ProxiesManaging {
    func reload() {
        
    }

    let manager = ProxiesManager()
    let reloader = TableViewReloader()

    let proxiesObserver = ProxiesObserver()

    private var dataSource: ProxiesTableViewDataSource?
    private var delegate: SenderPickerTableViewDelegate?
    weak var senderPickerDelegate: SenderPickerDelegate?
    var proxies = [Proxy]()

    override func viewDidLoad() {
        super.viewDidLoad()

        reloader.tableView = tableView
        manager.load(reloader)

//        dataSource = ProxiesTableViewDataSource(self)
        delegate = SenderPickerTableViewDelegate(delegate: senderPickerDelegate, controller: self)
        navigationItem.title = "Pick A Sender"
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
}

protocol SenderPickerDelegate: class {
    var sender: Proxy? { get set }
}
