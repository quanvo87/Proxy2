import UIKit

class MessagesTableViewDelegate: NSObject {
    private weak var convosManager: ConvosManaging?
    private weak var itemsToDeleteManager: ItemsToDeleteManaging?
    private weak var controller: UIViewController?
  
    func load(convosManager: ConvosManaging, itemsToDeleteManager: ItemsToDeleteManaging, controller: UIViewController?) {
        self.convosManager = convosManager
        self.itemsToDeleteManager = itemsToDeleteManager
        self.controller = controller
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
            controller?.navigationController?.showConvoViewController(convo)
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
