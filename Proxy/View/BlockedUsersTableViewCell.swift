import FirebaseDatabase
import UIKit

class BlockedUsersTableViewCell: UITableViewCell {
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameLabel: UILabel!
    
    let api = API.sharedInstance
    var blockedUser: BlockedUser?
    
    @IBAction func unblock(_ sender: AnyObject) {
        if let blockedUser = blockedUser {
            api.unblock(blockedUserId: blockedUser.id)
        }
    }
}
