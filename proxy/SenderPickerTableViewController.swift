import FirebaseDatabase

class SenderPickerTableViewController: UITableViewController {
    var dataSource: ProxiesTableViewDataSource?
    var delegate: SenderPickerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        let cancelButton = UIButton(type: .custom)
        cancelButton.addTarget(self, action: #selector(SenderPickerTableViewController.cancelPickingSender), for: .touchUpInside)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        cancelButton.setImage(UIImage(named: "cancel"), for: .normal)

        dataSource = ProxiesTableViewDataSource(tableView)
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        navigationItem.title = "Pick A Sender"

        tableView.dataSource = dataSource
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.isHidden = false
    }
}

extension SenderPickerTableViewController {
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = dataSource?.proxiesObserver.getProxies()[safe: indexPath.row] else {
            return
        }
        delegate?.setSender(to: proxy)
        _ = navigationController?.popViewController(animated: true)
    }
}

extension SenderPickerTableViewController {
    @objc func cancelPickingSender() {
        _ = navigationController?.popViewController(animated: true)
    }
}

protocol SenderPickerDelegate {
    func setSender(to proxy: Proxy)
}
