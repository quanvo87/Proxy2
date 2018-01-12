import UIKit

// todo: decouple dependencies
// todo: see where i can use lazy vars throughout app
class MakeNewMessageTableViewDataSource: NSObject {
    private weak var controller: MakeNewMessageViewController?

    init(_ controller: MakeNewMessageViewController) {
        self.controller = controller
    }
}

extension MakeNewMessageTableViewDataSource: UITableViewDataSource {
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.makeNewMessageSenderTableViewCell) as? MakeNewMessageSenderTableViewCell else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.makeNewMessageSenderTableViewCell, for: indexPath)
            }
            if let name = controller?.sender?.name {
                cell.nameLabel.text = name
            } else {
                cell.nameLabel.text = "Pick Your Sender"
            }
            cell.nameLabel.textColor = .blue
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 && controller?.proxiesManager?.proxies.count == 0 {
            return "Tap the bouncing button to make a new Proxy."
        } else {
            return nil
        }
    }
}
