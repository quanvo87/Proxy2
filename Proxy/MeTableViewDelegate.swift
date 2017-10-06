import FirebaseAuth
import UIKit

class MeTableViewDelegate: NSObject {
    weak var controller: MeTableViewController?

    func load(_ controller: MeTableViewController) {
        self.controller = controller
        controller.tableView.delegate = self
    }
}

extension MeTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        case 1:
            guard let blockedUsersVC = controller?.storyboard?.instantiateViewController(withIdentifier: Identifier.blockedUsersTableViewController) as? BlockedUsersTableViewController else { return }
            controller?.navigationController?.pushViewController(blockedUsersVC, animated: true)
        case 2:
            tableView.deselectRow(at: indexPath, animated: true)
            switch indexPath.row {
            case 0:
                let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
                    try? Auth.auth().signOut()
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                controller?.present(alert, animated: true)
            case 1:
                let alert = UIAlertController(title: "Proxy v0.0.1", message: "Contact: qvo1987@gmail.com\n\nIcons from icons8.com", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel) { action in
                })
                controller?.present(alert, animated: true)
            default: return
            }
        default:
            return
        }
    }
}
