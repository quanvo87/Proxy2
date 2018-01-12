import UIKit

class MakeNewMessageTableViewDelegate: NSObject {
    private weak var controller: MakeNewMessageViewController?

    init(_ controller: MakeNewMessageViewController) {
        self.controller = controller
    }
}

extension MakeNewMessageTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            indexPath.row == 0,
            let uid = controller?.uid,
            let manager = controller?.proxiesManager,
            let controller = controller else {
                return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let senderPickerViewController = SenderPickerViewController(uid: uid,
                                                                    manager: manager,
                                                                    senderPickerDelegate: controller)
        controller.navigationController?.pushViewController(senderPickerViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
