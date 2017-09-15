import UIKit

class MessagesTableViewDelegate: NSObject {
    private weak var controller: MessagesTableViewController?

    init(_ controller: MessagesTableViewController) {
        super.init()
        controller.tableView.delegate = self
        self.controller = controller
    }
}

extension MessagesTableViewDelegate: UITableViewDelegate {
    var convos: [Convo] {
        return controller?.convos ?? []
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let convo = convos[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            controller?.itemsToDelete[convo.key] = convo
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
        controller?.itemsToDelete.removeValue(forKey: convo.key)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
