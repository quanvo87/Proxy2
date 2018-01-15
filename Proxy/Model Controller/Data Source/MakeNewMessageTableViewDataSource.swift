import UIKit

// todo: decouple dependencies
class MakeNewMessageTableViewDataSource: NSObject {
    private weak var controller: UIViewController?
    private weak var delegate: SenderPickerDelegate?
    private weak var manager: ProxiesManaging?

    init(controller: UIViewController?,
         delegate: SenderPickerDelegate?,
         manager: ProxiesManaging?) {
        self.controller = controller
        self.delegate = delegate
        self.manager = manager
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
            if let name = delegate?.sender?.name {
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
        if section == 0 && manager?.proxies.count == 0 {
            return "Tap the bouncing button to make a new Proxy 🎉."
        } else {
            return nil
        }
    }
}
