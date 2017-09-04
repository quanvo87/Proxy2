class SenderPickerTableViewController: UITableViewController {
    private let dataSource = ProxiesTableViewDataSource()
    private weak var delegate: SenderPickerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        dataSource.observe(tableView)

        navigationItem.title = "Pick A Sender"

        tableView.dataSource = dataSource
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }

    func setDelegate(to delegate: SenderPickerDelegate) {
        self.delegate = delegate
    }
}

extension SenderPickerTableViewController {
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = dataSource.proxies[safe: indexPath.row] else {
            return
        }
        delegate?.setSender(to: proxy)
        _ = navigationController?.popViewController(animated: true)
    }
}

protocol SenderPickerDelegate: class {
    func setSender(to proxy: Proxy)
}
