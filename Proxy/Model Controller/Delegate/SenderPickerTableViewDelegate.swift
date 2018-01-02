import UIKit

class SenderPickerTableViewDelegate: NSObject {
    private var container: DependencyContaining = DependencyContainer.container
    private weak var delegate: SenderPickerDelegate?
    private weak var controller: UIViewController?

    func load(delegate: SenderPickerDelegate, controller: UIViewController, container: DependencyContaining) {
        self.delegate = delegate
        self.controller = controller
        self.container = container
    }
}

extension SenderPickerTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let proxy = container.proxiesManager.proxies[safe: indexPath.row] else {
            return
        }
        delegate?.sender = proxy
        _ = controller?.navigationController?.popViewController(animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
