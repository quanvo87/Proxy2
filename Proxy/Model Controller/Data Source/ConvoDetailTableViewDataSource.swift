import UIKit

class ConvoDetailTableViewDataSource: NSObject {
    private weak var convoManager: ConvoManaging?
    private weak var proxyManger: ProxyManaging?
    private weak var controller: UIViewController?

    func load(convoManager: ConvoManaging, proxyManger: ProxyManaging, controller: UIViewController) {
        self.convoManager = convoManager
        self.proxyManger = proxyManger
        self.controller = controller
    }
}

extension ConvoDetailTableViewDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.convoDetailReceiverProxyTableViewCell) as? ConvoDetailReceiverProxyTableViewCell,
                let convo = convoManager?.convo else {
                    return tableView.dequeueReusableCell(withIdentifier: Identifier.convoDetailReceiverProxyTableViewCell, for: indexPath)
            }
            cell.load(convo)
            return cell
        case 1:
            guard
                let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.convoDetailSenderProxyTableViewCell) as? SenderProxyTableViewCell,
                let proxy = proxyManger?.proxy else {
                    return tableView.dequeueReusableCell(withIdentifier: Identifier.convoDetailSenderProxyTableViewCell, for: indexPath)
            }
            cell.load(proxy)
            cell.accessoryType = .disclosureIndicator
            return cell
        case 2:
            let cell = UITableViewCell()
            switch indexPath.row {
            case 0:
                cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
                cell.textLabel?.text = "Leave conversation"
                cell.textLabel?.textColor = UIColor.red
                return cell
            case 1:
                cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
                cell.textLabel?.text = "Block user"
                cell.textLabel?.textColor = UIColor.red
                return cell
            default:
                break
            }
        default:
            break
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return 2
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch section {
        case 2:
            return "Users are not notified when you take these actions."
        default:
            return nil
        }
    }
}
