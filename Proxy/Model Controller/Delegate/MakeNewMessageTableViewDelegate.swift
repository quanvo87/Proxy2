import UIKit

class MakeNewMessageTableViewDelegate: NSObject {
    private let uid: String
    private weak var controller: UIViewController?
    private weak var proxiesManager: ProxiesManaging?
    private weak var senderManager: SenderManaging?

    init(uid: String,
         controller: UIViewController,
         proxiesManager: ProxiesManaging?,
         senderManager: SenderManaging?) {
        self.uid = uid
        self.controller = controller
        self.proxiesManager = proxiesManager
        self.senderManager = senderManager
    }
}

extension MakeNewMessageTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row == 0 else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let senderPickerViewController = SenderPickerViewController(uid: uid,
                                                                    proxiesManager: proxiesManager,
                                                                    senderManager: senderManager)
        controller?.navigationController?.pushViewController(senderPickerViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
