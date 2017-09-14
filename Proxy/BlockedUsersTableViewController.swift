import FirebaseDatabase
import UIKit


class BlockedUsersTableViewController: UITableViewController {

    let api = API.sharedInstance
    let ref = Database.database().reference()
    var blockedUsersRef = DatabaseReference()
    var blockedUsers = [BlockedUser]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Blocked Users"
        
        let cancelButton = UIButton(type: .custom)
        cancelButton.addTarget(self, action: #selector(BlockedUsersTableViewController.cancel), for: UIControlEvents.touchUpInside)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        cancelButton.setImage(UIImage(named: "cancel"), for: UIControlState.normal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        tableView.rowHeight = 60
        
        blockedUsersRef = ref.child(Child.blockedUsers).child(api.uid)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
        tabBarController?.tabBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.isHidden = false
    }
    
    deinit {
        blockedUsersRef.removeAllObservers()
    }
    
    @objc func cancel() {
        _ = navigationController?.popViewController(animated: true)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blockedUsers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let blockedUser = blockedUsers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.blockedUsersTableViewCell, for: indexPath as IndexPath) as! BlockedUsersTableViewCell
        
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