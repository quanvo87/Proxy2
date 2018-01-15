import SearchTextField

class MakeNewMessageTableViewDataSource: NSObject {
    private weak var controller: UIViewController?
    private weak var delegate: SenderPickerDelegate?
    private weak var proxiesManager: ProxiesManaging?
    private weak var searchTextFieldManager: SearchTextFieldManaging?

    init(controller: UIViewController?,
         delegate: SenderPickerDelegate?,
         proxiesManager: ProxiesManaging?,
         searchTextFieldManager: SearchTextFieldManaging?) {
        self.controller = controller
        self.delegate = delegate
        self.proxiesManager = proxiesManager
        self.searchTextFieldManager = searchTextFieldManager
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
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.makeNewMessageReceiverTableViewCell) as? MakeNewMessageReceiverTableViewCell else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.makeNewMessageReceiverTableViewCell, for: indexPath)
            }
            searchTextFieldManager?.textField = cell.receiverNameTextField
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 && proxiesManager?.proxies.count == 0 {
            return "Tap the bouncing button to make a new Proxy 🎉."
        } else {
            return nil
        }
    }
}
