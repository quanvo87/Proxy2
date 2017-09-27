import UIKit

class MeTableViewDataSource: NSObject {
    private weak var controller: MeObserving?

    init(_ controller: MeObserving) {
        super.init()
//        controller.tableView.dataSource = self
        self.controller = controller
    }
}

extension MeTableViewDataSource: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.meTableViewCell) as? MeTableViewCell else {
            return tableView.dequeueReusableCell(withIdentifier: Identifier.meTableViewCell, for: indexPath)
        }
        switch indexPath.section {
        case 0:
            cell.selectionStyle = .none
            switch indexPath.row {
            case 0:
                cell.subtitleLabel.text = controller?.messagesReceivedCount
                cell.titleLabel?.text = "Messages Received"
                UIImage.makeImage(named: "messagesReceived", completion: { (image) in
                    DispatchQueue.main.async {
                        cell.iconImageView.image = image
                    }
                })
            case 1:
                cell.subtitleLabel.text = controller?.messagesSentCount
                cell.titleLabel?.text = "Messages Sent"
                UIImage.makeImage(named: "messagesSent", completion: { (image) in
                    DispatchQueue.main.async {
                        cell.iconImageView.image = image
                    }
                })
            case 2:
                cell.subtitleLabel.text = controller?.proxiesInteractedWithCount
                cell.titleLabel?.text = "Proxies Interacted With"
                UIImage.makeImage(named: "proxiesInteractedWith", completion: { (image) in
                    DispatchQueue.main.async {
                        cell.iconImageView.image = image
                    }
                })
            default: break
            }
        case 1:
            cell.accessoryType = .disclosureIndicator
            cell.subtitleLabel.text = ""
            cell.titleLabel.text = "Blocked Users"
            UIImage.makeImage(named: "blockedUsers", completion: { (image) in
                DispatchQueue.main.async {
                    cell.iconImageView.image = image
                }
            })
        case 2:
            cell.subtitleLabel.text = ""
            switch indexPath.row {
            case 0:
                cell.titleLabel?.text = "Log Out"
                UIImage.makeImage(named: "logout", completion: { (image) in
                    DispatchQueue.main.async {
                        cell.iconImageView.image = image
                    }
                })
            case 1:
                cell.titleLabel?.text = "About"
                UIImage.makeImage(named: "info", completion: { (image) in
                    DispatchQueue.main.async {
                        cell.iconImageView.image = image
                    }
                })
            default: break
            }
        default: break
        }
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return 1
        case 2: return 2
        default: return 0
        }
    }
}
