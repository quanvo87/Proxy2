import FirebaseAuth
import UIKit

class MeTableViewDelegate: NSObject {
    private weak var controller: MeTableViewController?

    init(_ controller: MeTableViewController) {
        super.init()
        controller.tableView.delegate = self
        self.controller = controller
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
                let alert = UIAlertController(title: "Proxy v0.1.0", message: "Contact: qvo1987@gmail.com\n\nIcons from icons8.com", preferredStyle: .alert)
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