import UIKit

class SenderPickerTableViewDelegate: NSObject {
    weak var controller: SenderPickerTableViewController?

    func load(_ controller: SenderPickerTableViewController) {
        self.controller = controller
        controller.tableView.delegate = self
    }
}

extension SenderPickerTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let controller = controller,
            let delegate = controller.senderPickerDelegate,
            let proxy = controller.manager.proxies[safe: indexPath.row] else {
                return
        }
        delegate.sender = proxy
        _ = controller.navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
