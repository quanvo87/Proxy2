import UIKit

class SettingsViewController: UIViewController {
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private lazy var dataSource = SettingsTableViewDataSource(manager)
    private lazy var delegate = SettingsTableViewDelegate(self)
    private lazy var manager = UserStatsManager(uid: uid, tableView: tableView)

    init(uid: String, displayName: String?) {
        self.uid = uid

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = displayName

        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.settingsTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.settingsTableViewCell)
        tableView.rowHeight = 44

        view.addSubview(tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
