import UIKit

class MeViewController: UIViewController {
    private let manager = UserStatsManager()
    private let dataSource = MeTableViewDataSource()
    private let delegate = MeTableViewDelegate()
    private let tableView = UITableView(frame: .zero, style: .grouped)

    init(uid: String, displayName: String?) {
        super.init(nibName: nil, bundle: nil)

        navigationItem.title = displayName

        manager.load(uid: uid, tableView: tableView)

        dataSource.load(manager)

        delegate.load(controller: self)

        tableView.dataSource = dataSource
        tableView.delegate = delegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.meTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.meTableViewCell)
        tableView.rowHeight = 44
        
        view.addSubview(tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
