import UIKit

class ProxyTableViewDelegate: NSObject {
    private weak var controller: UIViewController?
    private weak var manager: ConvosManaging?

    func load(controller: UIViewController, manager: ConvosManaging) {
        self.controller = controller
        self.manager = manager
    }
}

extension ProxyTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if
            indexPath.section == 1,
            let row = tableView.indexPathForSelectedRow?.row,
            let convo = manager?.convos[safe: row]
        {
            tableView.deselectRow(at: indexPath, animated: true)
            controller?.showConvo(convo)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return CGFloat.leastNormalMagnitude
        case 1:
            return 15
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return 140
        case 1:
            return 80
        default:
            return 0
        }
    }
}
