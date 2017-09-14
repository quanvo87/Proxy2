import UIKit

class ProxyTableViewDelegate: NSObject {
//    private weak var convosObserver: ConvosObserver?
    private weak var tableViewController: ProxyTableViewController?

    init(_ tableViewController: ProxyTableViewController) {
        super.init()
//        self.convosObserver = (UIApplication.shared.delegate as? AppDelegate)?.convosObserver
        self.tableViewController = tableViewController
        tableViewController.tableView.delegate = self
    }
}

extension ProxyTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if  indexPath.section == 1,
            let row = tableView.indexPathForSelectedRow?.row,
//            let convo = tablev.convos[safe: row],
            let convoVC = tableViewController?.storyboard?.instantiateViewController(withIdentifier: Identifier.convoViewController) as? ConvoViewController {
//            convoVC.convo = convo
            tableViewController?.navigationController?.pushViewController(convoVC, animated: true)
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
