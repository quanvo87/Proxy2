import FirebaseMessaging
import UIKit

class SettingsViewController: UIViewController {
    private let database: Database
    private let loginManager: LoginManaging
    private let soundSwitchManager: SoundSwitchManaging
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private let userStatsObserver: UserStatsObserving
    private var messagesReceivedCount = "-"
    private var messagesSentCount = "-"
    private var proxiesInteractedWithCount = "-"

    init(database: Database = Shared.database,
         loginManager: LoginManaging = LoginManager(),
         uid: String,
         userStatsObserver: UserStatsObserving = UserStatsObserver(),
         soundSwitchManager: SoundSwitchManaging? = nil,
         displayName: String?) {
        self.database = database
        self.loginManager = loginManager
        self.uid = uid
        self.userStatsObserver = userStatsObserver

        if let soundSwitchManager = soundSwitchManager {
            self.soundSwitchManager = soundSwitchManager
        } else {
            self.soundSwitchManager = SoundSwitchManager(uid: uid)
        }

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = displayName

        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(
            UINib(nibName: String(describing: BasicTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: BasicTableViewCell.self)
        )
        tableView.rowHeight = 44

        let activityIndicatorView = UIActivityIndicatorView(view)
        userStatsObserver.observe(uid: uid) { [weak self] update in
            activityIndicatorView.removeFromSuperview()
            switch update {
            case .messagesReceived(let val):
                self?.messagesReceivedCount = val
            case .messagesSent(let val):
                self?.messagesSentCount = val
            case .proxiesInteractedWith(let val):
                self?.proxiesInteractedWithCount = val
            }
            self?.tableView.reloadSections(IndexSet(integer: 0), with: .automatic)
        }

        view.addSubview(tableView)

        activityIndicatorView.startAnimatingAndBringToFront()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: BasicTableViewCell.self)
            ) as? BasicTableViewCell else {
                return BasicTableViewCell()
        }
        switch indexPath.section {
        case 0:
            cell.selectionStyle = .none
            switch indexPath.row {
            case 0:
                cell.load(
                    icon: "messagesReceived",
                    title: "Messages Received",
                    subtitle: messagesReceivedCount
                )
            case 1:
                cell.load(
                    icon: "messagesSent",
                    title: "Messages Sent",
                    subtitle: messagesSentCount
                )
            case 2:
                cell.load(
                    icon: "proxiesInteractedWith",
                    title: "Proxies Interacted With",
                    subtitle: proxiesInteractedWithCount
                )
            default:
                break
            }
        case 1:
            switch indexPath.row {
            case 0:
                cell.accessoryView = soundSwitchManager.soundSwitch
                cell.load(icon: "sound", title: "Sound")
                cell.selectionStyle = .none
            case 1:
                cell.accessoryType = .disclosureIndicator
                cell.load(icon: "blockUser", title: "Blocked Users")
            case 2:
                cell.accessoryType = .disclosureIndicator
                cell.load(icon: "info", title: "About")
            default:
                break
            }
        case 2:
            cell.load(icon: "logout", title: "Log Out")
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
            return 3
        case 2:
            return 1
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
            case 1:
                let blockedUsersViewController = BlockedUsersViewController(uid: uid)
                navigationController?.pushViewController(blockedUsersViewController, animated: true)
            case 2:
                guard let aboutViewController = Shared.storyboard.instantiateViewController(
                    withIdentifier: String(describing: AboutViewController.self)
                    ) as? AboutViewController else {
                        return
                }
                navigationController?.pushViewController(aboutViewController, animated: true)
            default:
                return
            }
        case 2:
            let alert = Alert.make(
                title: "Log Out",
                message: "Are you sure you want to log out?"
            )
            alert.addAction(Alert.makeDestructiveAction(title: "Log Out") { [weak self] _ in
                if let registrationToken = Messaging.messaging().fcmToken, let uid = self?.uid {
                    self?.database.delete(.registrationToken(registrationToken), for: uid) { _ in }
                }
                self?.loginManager.logOut()
            })
            alert.addAction(Alert.makeCancelAction())
            present(alert, animated: true)
        default:
            return
        }
    }
}
