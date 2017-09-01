class SenderPickerTableViewController: UITableViewController {
    var dataSource = ProxiesTableViewDataSource()
    weak var delegate: SenderPickerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource.load(tableView)

        navigationItem.title = "Pick A Sender"

        tableView.dataSource = dataSource
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
}

extension SenderPickerTableViewController {
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = dataSource.proxiesObserver.getProxies()[safe: indexPath.row] else {
            return
        }
        delegate?.sender = proxy
        _ = navigationController?.popViewController(animated: true)
    }
}

protocol SenderPickerDelegate: class {
    var sender: Proxy? { get set }
}
