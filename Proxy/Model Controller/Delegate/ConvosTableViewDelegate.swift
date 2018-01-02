import UIKit

class ConvosTableViewDelegate: NSObject {
    private weak var convosManager: ConvosManager?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private weak var controller: UIViewController?
  
    func load(convosManager: ConvosManager, proxiesManager: ProxiesManaging?, unreadMessagesManager: UnreadMessagesManaging, controller: UIViewController?) {
        self.convosManager = convosManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager
        self.controller = controller
    }
}

extension ConvosTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let convo = convosManager?.convos[safe: indexPath.row] else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        controller?.navigationController?.showConvoViewController(convo: convo, proxiesManager: proxiesManager, unreadMessagesManager: unreadMessagesManager)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard
            let convoCount = convosManager?.convos.count,
            indexPath.row == convoCount - 1,
            let convo = convosManager?.convos[safe: indexPath.row] else {
                return
        }
        convosManager?.observer.getConvos(endingAtTimestamp: convo.timestamp)
    }
}
