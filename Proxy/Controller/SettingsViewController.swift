import FirebaseAuth
import UIKit

class SettingsViewController: UIViewController, UserStatsManaging {
    var messagesReceivedCount = "-" {
        didSet {
            tableView.reloadData()
        }
    }
    var messagesSentCount = "-" {
        didSet {
            tableView.reloadData()
        }
    }
    var proxiesInteractedWithCount = "-" {
        didSet {
            tableView.reloadData()
        }
    }
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private let userStatsObserver: UserStatsObserving

    init(uid: String,
         userStatsObserver: UserStatsObserving = UserStatsObserver(),
         displayName: String?) {
        self.uid = uid
        self.userStatsObserver = userStatsObserver

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = displayName

        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.settingsTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.settingsTableViewCell)
        tableView.rowHeight = 44

        userStatsObserver.load(uid: uid, userStatsManager: self)

        view.addSubview(tableView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.settingsTableViewCell) as? SettingsTableViewCell else {
            return tableView.dequeueReusableCell(withIdentifier: Identifier.settingsTableViewCell, for: indexPath)
        }
        switch indexPath.section {
        case 0:
            cell.selectionStyle = .none
            switch indexPath.row {
            case 0:
                cell.load(icon: "messagesReceived",
                          title: "Messages Received",
                          subtitle: messagesReceivedCount)
            case 1:
                cell.load(icon: "messagesSent",
                          title: "Messages Sent",
                          subtitle: messagesSentCount)
            case 2:
                cell.load(icon: "proxiesInteractedWith",
                          title: "Proxies Interacted With",
                          subtitle: proxiesInteractedWithCount)
            default:
                break
            }
        case 1:
            cell.subtitleLabel.text = ""
            switch indexPath.row {
            case 0:
                cell.load(icon: "info", title: "About", subtitle: "")
            case 1:
                cell.load(icon: "logout", title: "Log Out", subtitle: "")
            default:
                break
            }
        default:
            break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 3
        case 1:
            return 2
        default:
            return 0
        }
    }
}

// MARK: - UITableViewDelegate
extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 0:
                let alert = UIAlertController(title: "Proxy 0.1.0",
                                              message: "Send bugs, suggestions, etc., to:\nqvo1987@gmail.com\n\nIcons from icons8.com",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in })
                present(alert, animated: true)
            case 1:
                let alert = UIAlertController(title: "Log Out",
                                              message: "Are you sure you want to log out?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { [weak self] _ in
                    do {
                        try Auth.auth().signOut()
                    } catch {
                        self?.showErrorAlert(error)
                    }
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                present(alert, animated: true)
            default:
                return
            }
        default:
            return
        }
    }
}
