import FirebaseMessaging
import UIKit

// todo: toggle sound option
class SettingsViewController: UIViewController {
    private let database: Database
    private let loginManager: LoginManaging
    private let soundSwitch = UISwitch(frame: .zero)
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private let userStatsObserver: UserStatsObserving
    private var messagesReceivedCount = "-"
    private var messagesSentCount = "-"
    private var proxiesInteractedWithCount = "-"

    init(database: Database = Firebase(),
         loginManager: LoginManaging = LoginManager(),
         uid: String,
         userStatsObserver: UserStatsObserving = UserStatsObserver(),
         displayName: String?) {
        self.database = database
        self.loginManager = loginManager
        self.uid = uid
        self.userStatsObserver = userStatsObserver

        super.init(nibName: nil, bundle: nil)

        let activityIndicatorView = UIActivityIndicatorView(view)

        navigationItem.title = displayName

        soundSwitch.addTarget(self, action: #selector(toggleSound), for: .valueChanged)
        // do this in closure of get val from db
        // get value from database and set

        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(
            UINib(nibName: String(describing: SettingsTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: SettingsTableViewCell.self)
        )
        tableView.rowHeight = 44

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
            self?.tableView.reloadData()
        }

        view.addSubview(tableView)

        activityIndicatorView.startAnimatingAndBringToFront()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension SettingsViewController {
    @objc func toggleSound() {
        UserDefaults.standard.set(soundSwitch.isOn, forKey: "sound")
        // write to database
    }
}

// MARK: - UITableViewDataSource
extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: String(describing: SettingsTableViewCell.self)
            ) as? SettingsTableViewCell else {
                return SettingsTableViewCell()
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
            cell.accessoryView = soundSwitch
            cell.load(icon: "sound", title: "Sound")
            cell.selectionStyle = .none
        case 2:
            cell.accessoryType = .disclosureIndicator
            cell.load(icon: "info", title: "About")
        case 3:
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
            return 1
        case 2:
            return 1
        case 3:
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
        case 2:
            guard let aboutViewController = Constant.storyboard.instantiateViewController(
                withIdentifier: String(describing: AboutViewController.self)
                ) as? AboutViewController else {
                    return
            }
            navigationController?.pushViewController(aboutViewController, animated: true)
        case 3:
            let alert = Alert.make(
                title: "Log Out",
                message: "Are you sure you want to log out?"
            )
            alert.addAction(Alert.makeDestructiveAction(title: "Log Out") { [weak self] _ in
                if let registrationToken = Messaging.messaging().fcmToken, let uid = self?.uid {
                    self?.database.delete(userProperty: .registrationToken(registrationToken), for: uid) { _ in }
                }
                do {
                    try self?.loginManager.logOut()
                } catch {
                    StatusBar.showErrorBanner(subtitle: error.localizedDescription)
                }
            })
            alert.addAction(Alert.makeCancelAction())
            present(alert, animated: true)
        default:
            break
        }
        return
    }
}
