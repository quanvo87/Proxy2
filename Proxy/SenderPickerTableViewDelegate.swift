import UIKit

class SenderPickerTableViewDelegate: NSObject {
    private weak var controller: SenderPickerTableViewController?
    private weak var delegate: SenderPickerDelegate?

    init(delegate: SenderPickerDelegate?, controller: SenderPickerTableViewController) {
        super.init()
        controller.tableView.delegate = self
        self.controller = controller
        self.delegate = delegate
    }
}

extension SenderPickerTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let _controller = controller,
            let delegate = delegate,
            let proxy = controller?.proxies[safe: indexPath.row] else {
                return
        }
        delegate.sender = proxy
        _ = _controller.navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
