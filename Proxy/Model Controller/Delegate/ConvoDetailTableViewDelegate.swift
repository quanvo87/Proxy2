import UIKit

class ConvoDetailTableViewDelegate: NSObject {
    private weak var convoManager: ConvoManaging?
    private weak var proxyManager: ProxyManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private weak var controller: UIViewController?

    func load(convoManager: ConvoManaging, proxyManager: ProxyManaging, proxiesManager: ProxiesManaging?, unreadMessagesManager: UnreadMessagesManaging?, controller: UIViewController) {
        self.convoManager = convoManager
        self.proxyManager = proxyManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager
        self.controller = controller
    }
}

extension ConvoDetailTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let proxy = proxyManager?.proxy else {
            return
        }
        switch indexPath.section {
        case 1:
            controller?.showProxyController(proxy: proxy, proxiesManager: proxiesManager, unreadMessagesManager: unreadMessagesManager)
        case 2:
            switch indexPath.row {
            case 0:
                let alert = UIAlertController(title: "Delete Proxy?", message: "Your conversations for this proxy will also be deleted.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                    DB.deleteProxy(proxy) { (success) in
                        // todo: remove when put in proxy status observer
                        guard success else {
                            return
                        }
                        self.controller?.navigationController?.popViewController(animated: true)
                    }
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                controller?.present(alert, animated: true)
            default:
                return
            }
        default:
            return
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 80
        case 1:
            return 80
        default:
            return UITableViewAutomaticDimension
        }
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return 15
        case 1:
            return 15
        default:
            return UITableViewAutomaticDimension
        }
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        switch section {
        case 0:
            let view = UIView()
            let label = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.frame.width, height: 30))
            label.font = label.font.withSize(13)
            label.text = "Them"
            label.textColor = UIColor.gray
            view.addSubview(label)
            return view
        case 1:
            let view = UIView()
            let label = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.frame.width - 15, height: 30))
            label.autoresizingMask = .flexibleRightMargin
            label.font = label.font.withSize(13)
            label.text = "You"
            label.textAlignment = .right
            label.textColor = UIColor.gray
            view.addSubview(label)
            return view
        default:
            return nil
        }
    }
}
