import UIKit

class MessagesTableViewDelegate: NSObject {
    weak var controller: MessagesTableViewController?
}

extension MessagesTableViewDelegate: UITableViewDelegate {
    var convos: [Convo] {
        return controller?.convosManager.convos ?? []
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let convo = convos[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            controller?.buttonManager.itemsToDeleteManager?.itemsToDelete[convo.key] = convo
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            controller?.goToConvoVC(convo)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard
            tableView.isEditing,
            let convo = convos[safe: indexPath.row] else {
                return
        }
        controller?.buttonManager.itemsToDeleteManager?.itemsToDelete.removeValue(forKey: convo.key)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
