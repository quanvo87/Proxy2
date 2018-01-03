import UIKit

class ProxyTableViewDelegate: NSObject {
    private var container: DependencyContaining = DependencyContainer.container
    private weak var manager: ConvosManaging?
    private weak var controller: UIViewController?

    func load(manager: ConvosManaging, controller: UIViewController?, container: DependencyContaining) {
        self.manager = manager
        self.controller = controller
        self.container = container
    }
}

extension ProxyTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard
            indexPath.section == 1,
            let row = tableView.indexPathForSelectedRow?.row,
            let convo = manager?.convos[safe: row] else {
                return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        controller?.navigationController?.showConvoViewController(convo: convo, container: container)
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

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard
            indexPath.section == 1,
            let convoCount = manager?.convos.count,
            indexPath.row == convoCount - 1,
            let convo = manager?.convos[safe: indexPath.row] else {
                return
        }
        manager?.loadConvos(endingAtTimestamp: convo.timestamp, querySize: Setting.querySize)
    }
}
