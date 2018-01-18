import Device_swift
import MessageKit

class MakeNewMessageTableViewDataSource: NSObject {
    private let uid: String
    private weak var controller: UIViewController?
    private weak var inputBar: MessageInputBar?
    private weak var proxiesManager: ProxiesManaging?
    private weak var receiverManager: ReceiverIconImageManaging?
    private weak var receiverTextFieldDelegate: UITextFieldDelegate?
    private weak var senderManager: SenderManaging?
    private lazy var loader = ProxyNamesLoader(uid)

    init(uid: String,
         controller: UIViewController?,
         inputBar: MessageInputBar?,
         proxiesManager: ProxiesManaging?,
         receiverIconImageManager: ReceiverIconImageManaging?,
         receiverTextFieldDelegate: UITextFieldDelegate?,
         senderManager: SenderManaging?) {
        self.uid = uid
        self.controller = controller
        self.inputBar = inputBar
        self.proxiesManager = proxiesManager
        self.receiverManager = receiverIconImageManager
        self.receiverTextFieldDelegate = receiverTextFieldDelegate
        self.senderManager = senderManager
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
            cell.load(senderManager?.sender)
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.makeNewMessageReceiverTableViewCell) as? MakeNewMessageReceiverTableViewCell else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.makeNewMessageReceiverTableViewCell, for: indexPath)
            }
            cell.iconImageView.image = receiverManager?.receiverIconImage
            if let controller = controller {
                cell.receiverTextField.maxResultsListHeight = Int(controller.view.frame.height / 2)
            }
            let fontSize: CGFloat = isSmallDevice() ? 14 : 17
            cell.receiverTextField.comparisonOptions = [.caseInsensitive]
            cell.receiverTextField.delegate = receiverTextFieldDelegate
            cell.receiverTextField.highlightAttributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: fontSize)]
            cell.receiverTextField.itemSelectionHandler = { [weak self] (items, index) in
                guard let item = items[safe: index] else {
                    return
                }
                self?.receiverManager?.receiverIconImage = item.image
                cell.receiverTextField.text = item.title
                self?.inputBar?.inputTextView.becomeFirstResponder()
            }
            cell.receiverTextField.theme.cellHeight = 50
            cell.receiverTextField.theme.font = .systemFont(ofSize: fontSize)
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

    private func isSmallDevice() -> Bool {
        let deviceType = UIDevice.current.deviceType
        switch deviceType {
        case .iPhone2G:
            return true
        case .iPhone3G:
            return true
        case .iPhone3GS:
            return true
        case .iPhone4:
            return true
        case .iPhone4S:
            return true
        case .iPhone5:
            return true
        case .iPhone5C:
            return true
        case .iPhone5S:
            return true
        case .iPhoneSE:
            return true
        case .iPodTouch1G:
            return true
        case .iPodTouch2G:
            return true
        case .iPodTouch3G:
            return true
        case .iPodTouch4G:
            return true
        case .iPodTouch5G:
            return true
        default:
            return false
        }
    }
}
