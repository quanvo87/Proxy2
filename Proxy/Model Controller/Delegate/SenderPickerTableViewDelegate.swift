import UIKit

class SenderPickerTableViewDelegate: NSObject {
    private weak var manager: ProxiesManaging?
    private weak var delegate: SenderPickerDelegate?
    private weak var controller: UIViewController?

    func load(manager: ProxiesManaging, delegate: SenderPickerDelegate?, controller: UIViewController?) {
        self.manager = manager
        self.delegate = delegate
        self.controller = controller
    }
}

extension SenderPickerTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = manager?.proxies[safe: indexPath.row] else {
            return
        }
        delegate?.sender = proxy
        _ = controller?.navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}