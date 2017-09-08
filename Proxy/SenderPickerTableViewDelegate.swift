import UIKit

class SenderPickerTableViewDelegate: NSObject {
    private weak var delegate: SenderPickerDelegate?
    private weak var proxiesObserver: ProxiesObserver?
    private weak var tableViewController: SenderPickerTableViewController?

    init(delegate: SenderPickerDelegate?, tableViewController: SenderPickerTableViewController) {
        super.init()

        self.delegate = delegate
        self.proxiesObserver = (UIApplication.shared.delegate as? AppDelegate)?.proxiesObserver
        self.tableViewController = tableViewController

        tableViewController.tableView.delegate = self
    }
}

extension SenderPickerTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            let delegate = delegate,
            let proxy = proxiesObserver?.proxies[safe: indexPath.row],
            let viewController = tableViewController else {
                return
        }
        delegate.setSender(to: proxy)
        _ = viewController.navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
