//
//  MeTableViewController.swift
//  proxy
//
//  Created by Quan Vo on 10/24/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FacebookLogin

class MeTableViewController: UITableViewController {

    var messagesReceived = 0
    var messagesSent = 0
    var proxiesInteractedWith = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let user = user {
                self.navigationItem.title = user.displayName
            } else {
                self.navigationItem.title = ""
            }
        }
        
        tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: Identifiers.Cell)
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
                cell.subtitleLabel.text = String(messagesReceived)
            case 1:
                cell.iconImageView.image = UIImage(named: "messages-sent")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.titleLabel?.text = "Messages Sent"
                cell.subtitleLabel.text = String(messagesSent)
            case 2:
                cell.iconImageView.image = UIImage(named: "proxies-interacted-with")?.resize(toNewSize: size, isAspectRatio: isAspectRatio)
                cell.titleLabel?.text = "Proxies Interacted With"
                cell.subtitleLabel.text = String(proxiesInteractedWith)
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
        let alert = UIAlertController(title: "About proxy:", message: "Contact:\nqvo1987@gmail.com\n\nUpcoming features:\nsound in videos, location sharing", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .Cancel) { action in
        })
        self.presentViewController(alert, animated: true, completion: nil)
    }
}
