import UIKit

class ConvoDetailTableViewDelegate: NSObject {
    private weak var controller: UIViewController?
    private weak var convoManager: ConvoManaging?
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var proxyManager: ProxyManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?

    init(controller: UIViewController?,
         convoManager: ConvoManaging?,
         presenceManager: PresenceManaging?,
         proxiesManager: ProxiesManaging?,
         proxyManager: ProxyManaging?,
         unreadMessagesManager: UnreadMessagesManaging?) {
        self.controller = controller
        self.convoManager = convoManager
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.proxyManager = proxyManager
        self.unreadMessagesManager = unreadMessagesManager
    }
}

extension ConvoDetailTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard
            let proxy = proxyManager?.proxy,
            let presenceManager = presenceManager,
            let proxiesManager = proxiesManager,
            let unreadMessagesManager = unreadMessagesManager else {
                return
        }
        switch indexPath.section {
        case 1:
            controller?.navigationController?.showProxyController(proxy: proxy, presenceManager: presenceManager, proxiesManager: proxiesManager, unreadMessagesManager: unreadMessagesManager)
        case 2:
            switch indexPath.row {
            case 0:
                let alert = UIAlertController(title: "Delete Proxy?", message: "Your conversations for this proxy will be deleted.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                    DB.deleteProxy(proxy) { _ in
                        self?.controller?.navigationController?.popViewController(animated: true)
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
