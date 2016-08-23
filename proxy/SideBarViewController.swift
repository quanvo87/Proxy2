//
//  SideBarViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/20/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit
import FirebaseAuth
import FacebookLogin

class SideBarViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var sideBarTableView: UITableView!
    private var sideBarItems = [SideBarItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userNameLabel.text = ""
        
        sideBarItems = SideBarItems().getSideBarItems()
        
        sideBarTableView.delegate = self
        sideBarTableView.dataSource = self
        sideBarTableView.reloadData()
    }
    
    override func viewWillAppear(animated: Bool) {
        if userNameLabel.text == "" {
            setUsername()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func setUsername() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(SideBarViewController.setUsernameFromFacebook), name: "Fetched Username", object: nil)
        userNameLabel.text = API.sharedInstance.getUsername()
    }
    
    func setUsernameFromFacebook(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: String]
        userNameLabel.text = userInfo["username"]
    }
    
    func toggleSideBar() {
        self.revealViewController().revealToggle(self)
    }
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sideBarItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Side Bar Table View Cell", forIndexPath: indexPath) as! SideBarTableViewCell
        let sideBarItem = sideBarItems[indexPath.row]
        cell.textLabel?.text = sideBarItem.title
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let sideBarItemTitle = sideBarItems[indexPath.row].title
        switch sideBarItemTitle {
        case "Home":
            tapHome()
        case "Turn On Notifications":
            tapTurnOnNotifications()
        case "Trash":
            tapTrash()
        case "Log Out":
            tapLogOut()
        case "Delete Account":
            tapDeleteAccount()
        case "About":
            tapAbout()
        default:
            print("Error selecting Side Bar Menu Item.")
        }
    }
    
    func tapHome() {
        toggleSideBar()
    }
    
    func tapTurnOnNotifications() {
        
    }
    
    func tapTrash() {
        
    }
    
    func tapSuggestAWord() {
        
    }
    
    func tapLogOut() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .Alert)
        let yesButton: UIAlertAction = UIAlertAction(title: "Yes", style: .Default) { action in
            self.logOut()
        }
        let cancelButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action in
        }
        alert.addAction(yesButton)
        alert.addAction(cancelButton)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func logOut() {
        userNameLabel.text = ""
        
        let loginManager = LoginManager()
        loginManager.logOut()
        
        let firebaseAuth = FIRAuth.auth()
        do {
            try firebaseAuth?.signOut()
            API.sharedInstance.userDisplayName = ""
            API.sharedInstance.userLoggedIn = false
            toggleSideBar()
            let logInViewController = storyboard!.instantiateViewControllerWithIdentifier("Log In") as! LogInViewController
            self.presentViewController(logInViewController, animated: true, completion: nil)
        } catch let error as NSError {
            print ("Error signing out: \(error)")
        }
    }
    
    func tapDeleteAccount() {
        
    }
    
    func tapAbout() {
        
    }
}