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
    
    private var sideBarItems = [SideBarItem]()
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var sideBarTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sideBarItems = SideBarItems().sideBarItems
        setUpTableView()
    }
    
    override func viewWillAppear(animated: Bool) {
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let user = user {
                self.usernameLabel.text = user.displayName
            }
        }
    }
    
    func setUpTableView() {
        sideBarTableView.delegate = self
        sideBarTableView.dataSource = self
        sideBarTableView.reloadData()
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
        case Constants.SideBarItemNames.Home:
            tapHome()
        case Constants.SideBarItemNames.TurnOnNotifications:
            tapTurnOnNotifications()
        case Constants.SideBarItemNames.ReportAnIssue:
            reportAnIssue()
        case Constants.SideBarItemNames.Trash:
            tapTrash()
        case Constants.SideBarItemNames.LogOut:
            tapLogOut()
        case Constants.SideBarItemNames.DeleteAccount:
            tapDeleteAccount()
        case Constants.SideBarItemNames.About:
            tapAbout()
        default:
            self.showAlert("Error", message: "Error selecting Side Bar Menu Item.")
        }
    }
    
    func tapHome() {
        toggleSideBar()
    }
    
    func tapTurnOnNotifications() {
        
    }
    
    func reportAnIssue() {
        
    }
    
    func tapTrash() {
        
    }
    
    func tapSuggestAWord() {
        
    }
    
    func tapLogOut() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .Alert)
        let yesButton: UIAlertAction = UIAlertAction(title: "Yes", style: .Default) { action in
            let firebaseAuth = FIRAuth.auth()
            do {
                try firebaseAuth?.signOut()
                self.usernameLabel.text = ""
                self.toggleSideBar()
            } catch let error as NSError {
                self.showAlert("Error Logging Out", message: error.localizedDescription)
            }
        }
        let cancelButton: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action in
        }
        alert.addAction(yesButton)
        alert.addAction(cancelButton)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func tapDeleteAccount() {
        
    }
    
    func tapAbout() {
        
    }
}