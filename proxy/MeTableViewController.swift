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
    var messagesReceived = "0"
    
    var messagesSentRef = FIRDatabaseReference()
    var messagesSent = "0"
    
    var proxiesInteractedWithRef = FIRDatabaseReference()
    var proxiesInteractedWith = "0"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let user = user {
                self.navigationItem.title = user.displayName
            } else {
                self.navigationItem.title = ""
            }
        }
        
        messagesReceivedRef = ref.child(Path.MessagesReceived).child(api.uid).child(Path.MessagesReceived)
        messagesSentRef = ref.child(Path.MessagesSent).child(api.uid).child(Path.MessagesSent)
        proxiesInteractedWithRef = ref.child(Path.ProxiesInteractedWith).child(api.uid).child(Path.ProxiesInteractedWith)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        messagesReceivedRef.observeEventType(.Value, withBlock: { (snapshot) in
            self.messagesReceived = (snapshot.value as! Int).shortened()
            self.tableView.reloadData()
        })
        
        messagesSentRef.observeEventType(.Value, withBlock: { (snapshot) in
            self.messagesSent = (snapshot.value as! Int).shortened()
            self.tableView.reloadData()
        })
        
        proxiesInteractedWithRef.observeEventType(.Value, withBlock: { (snapshot) in
            self.proxiesInteractedWith = (snapshot.value as! Int).shortened()
            self.tableView.reloadData()
        })
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        
        messagesReceivedRef.removeAllObservers()
        messagesSentRef.removeAllObservers()
        proxiesInteractedWithRef.removeAllObservers()
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 3
        case 1: return 2
        default: return 0
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.MeTableViewCell, forIndexPath: indexPath) as! MeTableViewCell
        let size = CGSize(width: 30, height: 30)
        let isAspectRatio = true
        switch indexPath.section {
            
        case 0:
            cell.selectionStyle = .None
            switch indexPath.row {
            case 0:
                cell.iconImageView.image = UIImage(named: "messages-received")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.titleLabel?.text = "Messages Received"
                cell.subtitleLabel.text = messagesReceived
            case 1:
                cell.iconImageView.image = UIImage(named: "messages-sent")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.titleLabel?.text = "Messages Sent"
                cell.subtitleLabel.text = messagesSent
            case 2:
                cell.iconImageView.image = UIImage(named: "proxies-interacted-with")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.titleLabel?.text = "Proxies Interacted With"
                cell.subtitleLabel.text = proxiesInteractedWith
            default: break
            }
            
        case 1:
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
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        switch indexPath.section {
        case 1:
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            switch indexPath.row {
            case 0:
                logOut()
            case 1:
                showAbout()
            default:
                return
            }
        default:
            return
        }
    }
    
    func logOut() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .Default) { action in
            let firebaseAuth = FIRAuth.auth()
            do {
                try firebaseAuth?.signOut()
                let logInViewController  = self.storyboard!.instantiateViewControllerWithIdentifier("Log In View Controller") as! LogInViewController
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.window?.rootViewController = logInViewController
            } catch {}
            })
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel) { action in
            })
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func showAbout() {
        let alert = UIAlertController(title: "About proxy:", message: "Contact:\nqvo1987@gmail.com\n\nUpcoming features:\nsound in videos, location sharing\n\nIcons from icons8.com", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel) { action in
        })
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
