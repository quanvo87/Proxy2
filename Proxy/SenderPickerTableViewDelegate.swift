import UIKit

class SenderPickerTableViewDelegate: NSObject {
    private weak var delegate: SenderPickerDelegate?
    private weak var controller: SenderPickerTableViewController?

    init(delegate: SenderPickerDelegate?, controller: SenderPickerTableViewController) {
        super.init()
        controller.tableView.delegate = self
        self.delegate = delegate
        self.controller = controller
    }
}

extension SenderPickerTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let delegate = delegate,
            let proxy = controller?.proxies[safe: indexPath.row],
            let _controller = controller else {
                return
        }
        delegate.sender = proxy
        _ = _controller.navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
