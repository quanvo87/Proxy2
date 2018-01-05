import UIKit

class SenderPickerViewController: UIViewController {
    private let uid: String
    private let manager = ProxiesManager()
    private let dataSource = ProxiesTableViewDataSource()
    private let delegate = SenderPickerTableViewDelegate()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private weak var senderPickerDelegate: SenderPickerDelegate?

    init(uid: String, senderPickerDelegate: SenderPickerDelegate, container: DependencyContaining) {
        self.uid = uid
        self.senderPickerDelegate = senderPickerDelegate

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = "Pick A Sender"

        manager.load(uid: uid, controller: nil, manager: nil, tableView: tableView)

        dataSource.load(accessoryType: .none, container: container)
     
        delegate.load(delegate: senderPickerDelegate, controller: self, container: container)

        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.proxiesTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.proxiesTableViewCell)
        tableView.rowHeight = 60
        tableView.sectionHeaderHeight = 0
        
        view.addSubview(tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
