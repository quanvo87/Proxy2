import UIKit

class MeTableViewDataSource: NSObject {
    private weak var messagesReceivedManager: MessagesReceivedManaging?
    private weak var messagesSentManager: MessagesSentManaging?
    private weak var proxiesInteractedWithManager: ProxiesInteractedWithManaging?

    func load(messagesReceivedManager: MessagesReceivedManaging,
              messagesSentManager: MessagesSentManaging,
              proxiesInteractedWithManager: ProxiesInteractedWithManaging) {
        self.messagesReceivedManager = messagesReceivedManager
        self.messagesSentManager = messagesSentManager
        self.proxiesInteractedWithManager = proxiesInteractedWithManager
    }
}

extension MeTableViewDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Name.meTableViewCell) as? MeTableViewCell else {
            return tableView.dequeueReusableCell(withIdentifier: Name.meTableViewCell, for: indexPath)
        }
        switch indexPath.section {
        case 0:
            cell.selectionStyle = .none
            switch indexPath.row {
            case 0:
                cell.load(icon: "messagesReceived", title: "Messages Received", subtitle: messagesReceivedManager?.messagesReceivedCount)
            case 1:
                cell.load(icon: "messagesSent", title: "Messages Sent", subtitle: messagesSentManager?.messagesSentCount)
            case 2:
                cell.load(icon: "proxiesInteractedWith", title: "Proxies Interacted With", subtitle: proxiesInteractedWithManager?.proxiesInteractedWithCount)
            default:
                break
            }
        case 1:
            cell.accessoryType = .disclosureIndicator
            cell.load(icon: "blockedUsers", title: "Blocked Users", subtitle: "")
        case 2:
            cell.subtitleLabel.text = ""
            switch indexPath.row {
            case 0:
                cell.load(icon: "logout", title: "Log Out", subtitle: "")
            case 1:
                cell.load(icon: "info", title: "About", subtitle: "")
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
            return 1
        case 2:
            return 2
        default:
            return 0
        }
    }
}
