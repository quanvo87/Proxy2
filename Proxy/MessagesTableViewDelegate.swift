import UIKit

class MessagesTableViewDelegate: NSObject {
    private weak var controller: UITableViewController?
    weak var manager: ConvosManager?
    // item deleter

    init(_ controller: UITableViewController) {
        super.init()
        self.controller = controller
        controller.tableView.delegate = self
    }
}

extension MessagesTableViewDelegate: UITableViewDelegate {
    var convos: [Convo] {
        return manager?.convos ?? []
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let convo = convos[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
//            controller?.set(convo, forKey: convo.key)
//            controller?.itemsToDelete[convo.key] = convo
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
//        controller?.remove(atKey: convo.key)
//        controller?.itemsToDelete.removeValue(forKey: convo.key)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
