import UIKit

class SettingsTableViewDataSource: NSObject {
    private weak var manager: UserStatsManaging?

    init(_ manager: UserStatsManaging) {
        self.manager = manager
    }
}

extension SettingsTableViewDataSource: UITableViewDataSource {
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
                cell.load(icon: "messagesReceived", title: "Messages Received", subtitle: manager?.messagesReceivedCount)
            case 1:
                cell.load(icon: "messagesSent", title: "Messages Sent", subtitle: manager?.messagesSentCount)
            case 2:
                cell.load(icon: "proxiesInteractedWith", title: "Proxies Interacted With", subtitle: manager?.proxiesInteractedWithCount)
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
