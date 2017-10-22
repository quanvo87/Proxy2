import UIKit

class SenderPickerViewController: UIViewController {
    private let dataSource = ProxiesTableViewDataSource()
    private let delegate = SenderPickerTableViewDelegate()
    private let manager = ProxiesManager()
    private let tableView = UITableView()
    private let uid: String
    private weak var senderPickerDelegate: SenderPickerDelegate?

    init(senderPickerDelegate: SenderPickerDelegate, uid: String) {
        self.senderPickerDelegate = senderPickerDelegate
        self.uid = uid

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "Pick A Sender"

        dataSource.load(manager: manager, showDisclosureIndicator: false)
        delegate.load(controller: self, delegate: senderPickerDelegate, manager: manager)
        manager.load(uid: uid, tableView: tableView)
        
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Name.proxiesTableViewCell, bundle: nil), forCellReuseIdentifier: Name.proxiesTableViewCell)
        tableView.rowHeight = 60
        tableView.separatorStyle = .none

        view.addSubview(tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
