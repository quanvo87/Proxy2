import UIKit

class SenderPickerTableViewDelegate: NSObject {
    private weak var controller: UIViewController?
    private weak var proxiesManager: ProxiesManaging?
    private weak var senderManager: SenderManaging?

    init(controller: UIViewController,
         proxiesManager: ProxiesManaging?,
         senderManager: SenderManaging?) {
        self.controller = controller
        self.proxiesManager = proxiesManager
        self.senderManager = senderManager
    }
}

extension SenderPickerTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = proxiesManager?.proxies[safe: indexPath.row] else {
            return
        }
        senderManager?.sender = proxy
        _ = controller?.navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
