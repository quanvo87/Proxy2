import FirebaseAuth
import UIKit

class SettingsTableViewDelegate: NSObject {
    private weak var controller: UIViewController?

    func load(_ controller: UIViewController) {
        self.controller = controller
    }
}

extension SettingsTableViewDelegate: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.section {
        case 1:
            switch indexPath.row {
            case 0:
                let alert = UIAlertController(title: "Proxy v0.0.1", message: "Send bugs, suggestions, etc., to:\nqvo1987@gmail.com\n\nIcons from icons8.com", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .cancel) { _ in })
                controller?.present(alert, animated: true)
            case 1:
                let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
                    try? Auth.auth().signOut()
                })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                controller?.present(alert, animated: true)
            default:
                return
            }
        default:
            return
        }
    }
}