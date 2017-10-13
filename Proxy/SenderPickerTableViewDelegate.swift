import UIKit

class SenderPickerTableViewDelegate: NSObject {
    private weak var controller: UITableViewController?
    private weak var delegate: SenderPickerDelegate?
    private weak var manager: ProxiesManaging?

    func load(controller: UITableViewController, delegate: SenderPickerDelegate?, manager: ProxiesManaging) {
        self.controller = controller
        self.delegate = delegate
        self.manager = manager
        controller.tableView.delegate = self
    }
}

extension SenderPickerTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = manager?.proxies[safe: indexPath.row] else { return }
        delegate?.sender = proxy
        _ = controller?.navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
