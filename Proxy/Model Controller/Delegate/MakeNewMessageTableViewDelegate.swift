import UIKit

class MakeNewMessageTableViewDelegate: NSObject {
    private let uid: String
    private weak var controller: UIViewController?
    private weak var delegate: SenderPickerDelegate?
    private weak var manager: ProxiesManaging?

    init(uid: String,
         controller: UIViewController,
         delegate: SenderPickerDelegate?,
         manager: ProxiesManaging?) {
        self.uid = uid
        self.controller = controller
        self.delegate = delegate
        self.manager = manager
    }
}

extension MakeNewMessageTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row == 0 else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let senderPickerViewController = SenderPickerViewController(uid: uid,
                                                                    manager: manager,
                                                                    senderPickerDelegate: delegate)
        controller?.navigationController?.pushViewController(senderPickerViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
