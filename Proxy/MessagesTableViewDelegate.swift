import UIKit

class MessagesTableViewDelegate: NSObject {
    private weak var convosObserver: ConvosObserver?
    private weak var tableViewController: MessagesTableViewController?

    init(_ tableViewController: MessagesTableViewController) {
        super.init()
        self.convosObserver = (UIApplication.shared.delegate as? AppDelegate)?.convosObserver
        self.tableViewController = tableViewController
        tableViewController.tableView.delegate = self
    }
}

extension MessagesTableViewDelegate: UITableViewDelegate {
    var convos: [Convo] {
        return convosObserver?.convos ?? []
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let convo = convos[safe: indexPath.row] else {
            return
        }
        if tableView.isEditing {
            tableViewController?.itemsToDelete[convo.key] = convo
        } else {
            tableView.deselectRow(at: indexPath, animated: true)
            tableViewController?.goToConvoVC(convo)
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard
            tableView.isEditing,
            let convo = convos[safe: indexPath.row] else {
                return
        }
        tableViewController?.itemsToDelete.removeValue(forKey: convo.key)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}
