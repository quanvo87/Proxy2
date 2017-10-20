/* BEING REFACTORED */

import FirebaseDatabase
import UIKit

class BlockedUsersTableViewController: UITableViewController {
    var blockedUsers = [BlockedUser]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Blocked Users"
        tableView.rowHeight = 60
        
//        blockedUsersRef = ref.child(Child.blockedUsers).child(api.uid)
//        blockedUsersRef.queryOrdered(byChild: Child.Created).observe(.value, with: { (data) in
//            var blockedUsers = [BlockedUser]()
//            for child in data.children {
//                if let blockedUser = BlockedUser(anyObject: (child as! DataSnapshot).value as AnyObject) {
//                    blockedUsers.append(blockedUser)
//                }
//            }
//            self.blockedUsers = blockedUsers.reversed()
//            self.tableView.reloadData()
//        })
    }
}

extension BlockedUsersTableViewController {
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUsers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let blockedUser = blockedUsers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: Name.blockedUsersTableViewCell, for: indexPath as IndexPath) as! BlockedUsersTableViewCell
        
        cell.blockedUser = blockedUser
        
        cell.iconImageView.image = nil
//        cell.iconImageView.kf.indicatorType = .activity
//        api.getURL(forIconName: blockedUser.icon) { (url) in
//            cell.iconImageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil, completionHandler: nil)
//        }

        cell.nameLabel.text = blockedUser.name
        cell.nicknameLabel.text = blockedUser.nickname
        
        cell.accessoryType = .none
        cell.selectionStyle = .none
        
        return cell
    }
}
