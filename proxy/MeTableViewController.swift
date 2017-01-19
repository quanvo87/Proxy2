//
//  MeTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 10/24/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

class MeTableViewController: UITableViewController {

    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    
    var messagesReceivedRef = FIRDatabaseReference()
    var messagesReceived = ""
    
    var messagesSentRef = FIRDatabaseReference()
    var messagesSent = ""
    
    var proxiesInteractedWithRef = FIRDatabaseReference()
    var proxiesInteractedWith = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FIRAuth.auth()?.addStateDidChangeListener { auth, user in
            if let user = user {
                self.navigationItem.title = user.displayName
            }
        }
        
        messagesReceivedRef = ref.child(Path.MessagesReceived).child(api.uid).child(Path.MessagesReceived)
        messagesSentRef = ref.child(Path.MessagesSent).child(api.uid).child(Path.MessagesSent)
        proxiesInteractedWithRef = ref.child(Path.ProxiesInteractedWith).child(api.uid).child(Path.ProxiesInteractedWith)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        messagesReceivedRef.observe(.value, with: { (snapshot) in
            self.messagesReceived = (snapshot.value as! Int).formatted()
            self.tableView.reloadData()
        })
        
        messagesSentRef.observe(.value, with: { (snapshot) in
            self.messagesSent = (snapshot.value as! Int).formatted()
            self.tableView.reloadData()
        })
        
        proxiesInteractedWithRef.observe(.value, with: { (snapshot) in
            self.proxiesInteractedWith = (snapshot.value as! Int).formatted()
            self.tableView.reloadData()
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        messagesReceivedRef.removeAllObservers()
        messagesSentRef.removeAllObservers()
        proxiesInteractedWithRef.removeAllObservers()
    }

    // MARK: - Table view data source
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return 1
        case 2: return 2
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifiers.MeTableViewCell, for: indexPath as IndexPath) as! MeTableViewCell
        let size = CGSize(width: 30, height: 30)
        let isAspectRatio = true
        switch indexPath.section {
            
        case 0:
            cell.selectionStyle = .none
            switch indexPath.row {
            case 0:
                cell.iconImageView.image = UIImage(named: "messages-received")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.subtitleLabel.text = messagesReceived
                cell.titleLabel?.text = "Messages Received"
            case 1:
                cell.iconImageView.image = UIImage(named: "messages-sent")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.subtitleLabel.text = messagesSent
                cell.titleLabel?.text = "Messages Sent"
            case 2:
                cell.iconImageView.image = UIImage(named: "proxies-interacted-with")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.subtitleLabel.text = proxiesInteractedWith
                cell.titleLabel?.text = "Proxies Interacted With"
            default: break
            }
            
        case 1:
            cell.accessoryType = .disclosureIndicator
            cell.iconImageView.image = UIImage(named: "blocked")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
            cell.subtitleLabel.text = ""
            cell.titleLabel.text = "Blocked Users"
            
        case 2:
            cell.subtitleLabel.text = ""
            switch indexPath.row {
            case 0:
                cell.iconImageView.image = UIImage(named: "logout")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.titleLabel?.text = "Log Out"
            case 1:
                cell.iconImageView.image = UIImage(named: "about")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.titleLabel?.text = "About"
            default: break
            }
            
        default: break
        }
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch indexPath.section {
        
        // Show blocked users
        case 1:
            let dest = self.storyboard!.instantiateViewController(withIdentifier: Identifiers.BlockedUsersTableViewController) as! BlockedUsersTableViewController
            navigationController?.pushViewController(dest, animated: true)
            
        case 2:
            tableView.deselectRow(at: indexPath, animated: true)
            switch indexPath.row {
            
            // Log out
            case 0:
                let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { action in
                    let firebaseAuth = FIRAuth.auth()
                    do {
                        try firebaseAuth?.signOut()
                        let logInViewController  = self.storyboard!.instantiateViewController(withIdentifier: "Log In View Controller") as! LogInViewController
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        appDelegate.window?.rootViewController = logInViewController
                    } catch {}
                    })
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { action in
                    })
                present(alert, animated: true, completion: nil)
                
            // Show About
            case 1:
                let alert = UIAlertController(title: "About Proxy:", message: "Contact: qvo1987@gmail.com\n\nUpcoming features: sound in videos, location sharing\n\nIcons from icons8.com\n\nLibraries used: Kingfisher, JSQMessagesViewController, Fusuma, MobilePlayer, VideoSplashKit, RAMReel\n\nVersion 0.1", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .cancel) { action in
                    })
                self.present(alert, animated: true, completion: nil)
                
            default: return
            }
        default:
            return
        }
    }
}
