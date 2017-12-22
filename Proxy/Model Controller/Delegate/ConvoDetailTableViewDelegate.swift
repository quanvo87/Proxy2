import UIKit

class ConvoDetailTableViewDelegate: NSObject {
    private weak var convoManager: ConvoManaging?
    private weak var proxyManager: ProxyManaging?
    private weak var controller: UIViewController?

    func load(convoManager: ConvoManaging, proxyManager: ProxyManaging, controller: UIViewController) {
        self.convoManager = convoManager
        self.proxyManager = proxyManager
        self.controller = controller
    }
}

extension ConvoDetailTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 1:
            guard let proxy = proxyManager?.proxy else {
                return
            }
            controller?.showProxyController(proxy)
        case 2:
            switch indexPath.row {
            case 0:
                guard let convo = convoManager?.convo else {
                    return
                }
                let alert = UIAlertController(title: "Leave Conversation?", message: "The other user will not be notified.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { (void) in
                    DBConvo.leaveConvo(convo) { (_) in }
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                controller?.present(alert, animated: true)
            case 1:
                let alert = UIAlertController(title: "Block User?", message: "You will no longer see any conversations with this user. You can unblock users in the 'Me' tab.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Block", style: .destructive) { (_) in
                    // todo: implement blocking
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
