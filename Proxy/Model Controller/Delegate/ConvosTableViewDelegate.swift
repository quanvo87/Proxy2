import UIKit

class ConvosTableViewDelegate: NSObject {
    private var container: DependencyContaining = DependencyContainer.container
    private weak var convosManager: ConvosManager?
    private weak var controller: UIViewController?
  
    func load(convosManager: ConvosManager, controller: UIViewController, container: DependencyContaining) {
        self.convosManager = convosManager
        self.controller = controller
        self.container = container
    }
}

extension ConvosTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let convo = convosManager?.convos[safe: indexPath.row] else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        controller?.navigationController?.showConvoViewController(convo: convo, container: container)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard
            let convoCount = convosManager?.convos.count,
            indexPath.row == convoCount - 1,
            let convo = convosManager?.convos[safe: indexPath.row] else {
                return
        }
        convosManager?.getConvos(endingAtTimestamp: convo.timestamp, querySize: Setting.querySize)
    }
}
