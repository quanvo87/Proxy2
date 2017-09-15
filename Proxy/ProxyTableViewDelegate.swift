import UIKit

class ProxyTableViewDelegate: NSObject {
    private weak var controller: ProxyTableViewController?

    init(_ controller: ProxyTableViewController) {
        super.init()
        controller.tableView.delegate = self
        self.controller = controller
    }
}

extension ProxyTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if  indexPath.section == 1,
            let row = tableView.indexPathForSelectedRow?.row,
            let convo = controller?.convos[safe: row],
            let convoVC = controller?.storyboard?.instantiateViewController(withIdentifier: Identifier.convoViewController) as? ConvoViewController {
            convoVC.convo = convo
            controller?.navigationController?.pushViewController(convoVC, animated: true)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0: return CGFloat.leastNormalMagnitude
        case 1: return 15
        default: return 0
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0: return 140
        case 1: return 80
        default: return 0
        }
    }
}
