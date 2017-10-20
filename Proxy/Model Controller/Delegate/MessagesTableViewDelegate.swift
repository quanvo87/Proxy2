import UIKit

class MessagesTableViewDelegate: NSObject {
    private weak var controller: UIViewController?
    private weak var convosManager: ConvosManaging?
    private weak var itemsToDeleteManager: ItemsToDeleteManaging?

    func load(controller: UIViewController, convosManager: ConvosManaging, itemsToDeleteManager: ItemsToDeleteManaging) {
        self.controller = controller
        self.convosManager = convosManager
        self.itemsToDeleteManager = itemsToDeleteManager
    }
}

extension MessagesTableViewDelegate: UITableViewDelegate {
    var convos: [Convo] {
        return convosManager?.convos ?? []
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let convo = convos[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            itemsToDeleteManager?.itemsToDelete[convo.key] = convo
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            controller?.showConvoController(convo)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard
            tableView.isEditing,
            let convo = convos[safe: indexPath.row] else {
                return
        }
        itemsToDeleteManager?.itemsToDelete.removeValue(forKey: convo.key)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
