import UIKit

class SettingsViewController: UIViewController {
    private let dataSource = SettingsTableViewDataSource()
    private let delegate = SettingsTableViewDelegate()
    private let manager = UserStatsManager()
    private let tableView = UITableView(frame: .zero, style: .grouped)

    init(uid: String, displayName: String?) {
        super.init(nibName: nil, bundle: nil)

        dataSource.load(manager)

        delegate.load(self)

        manager.load(uid: uid, tableView: tableView)

        navigationItem.title = displayName

        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.settingsTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.settingsTableViewCell)
        tableView.rowHeight = 44
        
        view.addSubview(tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
