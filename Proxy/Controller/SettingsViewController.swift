import FirebaseMessaging
import UIKit

class SettingsViewController: UIViewController {
    private let database: Database
    private let loginManager: LoginManaging
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private let userStatsObserver: UserStatsObserving
    private var messagesReceivedCount = "-"
    private var messagesSentCount = "-"
    private var proxiesInteractedWithCount = "-"
    private lazy var activityIndicatorView: UIActivityIndicatorView? = UIActivityIndicatorView(
        view: view,
        subview: tableView
    )

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

        activityIndicatorView?.startAnimating()

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
            self?.activityIndicatorView?.stopAnimatingAndRemoveFromSuperview()
            self?.activityIndicatorView = nil
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
                let alert = Alert.make(
                    title: "Proxy 0.1.0",
                    message: """
                        Send bugs, suggestions, etc., to:

                        qvo1987@gmail.com

                        Icons and sounds from https://icons8.com/

                        Login videos from http://coverr.co/
                        """
                )
                alert.addAction(Alert.makeOkAction())
                present(alert, animated: true)
            case 1:
                let alert = Alert.make(
                    title: "Log Out",
                    message: "Are you sure you want to log out?"
                )
                alert.addAction(Alert.makeDestructiveAction(title: "Log Out") { [weak self] _ in
                    if let registrationToken = Messaging.messaging().fcmToken, let uid = self?.uid {
                        self?.database.deleteRegistrationToken(registrationToken, for: uid) { _ in }
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
                return
            }
        default:
            return
        }
    }
}
