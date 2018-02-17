import FirebaseAuth
import UIKit

class SettingsViewController: UIViewController {
    private let auth: Auth
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private let userStatsObserver: UserStatsObserving
    private var messagesReceivedCount = "-"
    private var messagesSentCount = "-"
    private var proxiesInteractedWithCount = "-"

    init(auth: Auth = Auth.auth(),
         uid: String,
         userStatsObserver: UserStatsObserving = UserStatsObserver(),
         displayName: String?) {
        self.auth = auth
        self.uid = uid
        self.userStatsObserver = userStatsObserver

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = displayName

        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(
            UINib(nibName: String(describing: SettingsTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: SettingsTableViewCell.self)
        )
        tableView.rowHeight = 44

        userStatsObserver.observe(uid: uid) { [weak self] update in
            switch update {
            case .messagesReceived(let val):
                self?.messagesReceivedCount = val
            case .messagesSent(let val):
                self?.messagesSentCount = val
            case .proxiesInteractedWith(let val):
                self?.proxiesInteractedWithCount = val
            }
            self?.tableView.reloadData()
        }

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
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: SettingsTableViewCell.self)
            ) as? SettingsTableViewCell else {
                assertionFailure()
                return SettingsTableViewCell()
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
                let alert = Alert.makeAlert(
                    title: "Proxy 0.1.0",
                    message: "Send bugs, suggestions, etc., to:\nqvo1987@gmail.com"
                )
                alert.addAction(Alert.makeOkAction())
                present(alert, animated: true)
            case 1:
                let alert = Alert.makeAlert(
                    title: "Log Out",
                    message: "Are you sure you want to log out?"
                )
                alert.addAction(Alert.makeDestructiveAction(title: "Log Out") { [weak self] _ in
                    do {
                        try self?.auth.signOut()
                    } catch {
                        self?.showErrorBanner(error)
                    }
                })
                alert.addAction(Alert.makeCancelAction())
                present(alert, animated: true)
            default:
                return
            }
        default:
            return
        }
    }
}
