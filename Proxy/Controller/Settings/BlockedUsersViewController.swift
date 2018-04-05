import UIKit

class BlockedUsersViewController: UIViewController {
    private let blockedUsersObserver: BlockedUsersObserving
    private let database: Database
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private var blockedUsers = [BlockedUser]()

    init(blockedUsersObserver: BlockedUsersObserving = BlockedUsersObserver(),
         database: Database = Shared.database,
         uid: String) {
        self.blockedUsersObserver = blockedUsersObserver
        self.database = database
        self.uid = uid

        super.init(nibName: nil, bundle: nil)

        let activityIndicatorView = UIActivityIndicatorView(view)
        blockedUsersObserver.observe(uid: uid) { [weak self] blockedUsers in
            activityIndicatorView.removeFromSuperview()
            self?.blockedUsers = blockedUsers
            self?.tableView.reloadData()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Edit",
            style: .plain,
            target: self,
            action: #selector(didTapEditButton)
        )
        navigationItem.title = "Blocked Users"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.sectionHeaderHeight = 0

        view.addSubview(tableView)

        activityIndicatorView.startAnimatingAndBringToFront()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension BlockedUsersViewController {
    @objc func didTapEditButton() {
        if tableView.isEditing {
            tableView.isEditing = false
            navigationItem.rightBarButtonItem?.title = "Edit"
        } else {
            tableView.isEditing = true
            navigationItem.rightBarButtonItem?.title = "Done"
        }
    }
}

extension BlockedUsersViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let blockedUser = blockedUsers[indexPath.row]
        let cell = UITableViewCell()
        cell.selectionStyle = .none
        cell.textLabel?.text = blockedUser.blockeeProxyName
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUsers.count
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if blockedUsers.isEmpty {
            return "You are not blocking any users 🙂."
        } else {
            return nil
        }
    }
}

extension BlockedUsersViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView,
                   commit editingStyle: UITableViewCellEditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let blockedUser = blockedUsers[indexPath.row]
            database.unblock(blockedUser) { _ in }
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
