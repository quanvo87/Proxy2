import SearchTextField

class MakeNewMessageTableViewDataSource: NSObject {
    private let uid: String
    private var firstLoad = true
    private weak var controller: UIViewController?
    private weak var delegate: SenderPickerDelegate?
    private weak var proxiesManager: ProxiesManaging?
    private weak var receiverManager: ReceiverIconImageManaging?
    private weak var receiverTextFieldDelegate: UITextFieldDelegate?
    private lazy var loader = ProxyNamesLoader(uid)

    init(uid: String,
         controller: UIViewController?,
         delegate: SenderPickerDelegate?,
         proxiesManager: ProxiesManaging?,
         receiverIconImageManager: ReceiverIconImageManaging?,
         receiverTextFieldDelegate: UITextFieldDelegate?) {
        self.uid = uid
        self.controller = controller
        self.delegate = delegate
        self.proxiesManager = proxiesManager
        self.receiverManager = receiverIconImageManager
        self.receiverTextFieldDelegate = receiverTextFieldDelegate
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
            cell.load(delegate?.sender)
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.makeNewMessageReceiverTableViewCell) as? MakeNewMessageReceiverTableViewCell else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.makeNewMessageReceiverTableViewCell, for: indexPath)
            }
            cell.iconImageView.image = receiverManager?.receiverIconImage
            if firstLoad {
                cell.receiverTextField.becomeFirstResponder()
                firstLoad = false
            }
            if let controller = controller {
                cell.receiverTextField.maxResultsListHeight = Int(controller.view.frame.height / 2)
            }
            cell.receiverTextField.comparisonOptions = [.caseInsensitive]
            cell.receiverTextField.delegate = receiverTextFieldDelegate
            cell.receiverTextField.highlightAttributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 17)]
            cell.receiverTextField.itemSelectionHandler = { [weak self] (items, index) in
                guard let item = items[safe: index] else {
                    return
                }
                self?.receiverManager?.receiverIconImage = item.image
                cell.receiverTextField.text = item.title
                cell.receiverTextField.becomeFirstResponder()
            }
            cell.receiverTextField.theme.cellHeight = 50
            cell.receiverTextField.theme.font = .systemFont(ofSize: 17)
            cell.receiverTextField.theme.separatorColor = UIColor.lightGray.withAlphaComponent(0.5)
            cell.receiverTextField.userStoppedTypingHandler = { [weak self] in
                guard
                    let query = cell.receiverTextField.text,
                    query.count > 0 else {
                        return
                }
                self?.receiverManager?.receiverIconImage = nil
                cell.receiverTextField.showLoadingIndicator()
                self?.loader.load(query) { (items) in
                    cell.receiverTextField.filterItems(items)
                    cell.receiverTextField.stopLoadingIndicator()
                }
            }
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
