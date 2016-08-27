//
//  SettingsViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/20/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FacebookLogin

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var settingsItems = [SettingsItem]()
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var sideBarTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        settingsItems = SettingsItems().settingsItems
        setUpUI()
        setUpTableView()
    }
    
    func setUpUI() {
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let user = user {
                self.navigationItem.title = user.displayName
            } else {
                self.navigationItem.title = ""
            }
        }
    }
    
    func setUpTableView() {
        self.automaticallyAdjustsScrollViewInsets = false
        sideBarTableView.delegate = self
        sideBarTableView.dataSource = self
        sideBarTableView.reloadData()
    }
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsItems.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Settings Table View Cell", forIndexPath: indexPath) as! SettingsTableViewCell
        let settingsItem = settingsItems[indexPath.row]
        cell.textLabel?.text = settingsItem.title
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let settingsItemTitle = settingsItems[indexPath.row].title
        switch settingsItemTitle {
        case Constants.SettingsItemNames.TurnOnNotifications:
            tapTurnOnNotifications()
        case Constants.SettingsItemNames.ReportAnIssue:
            reportAnIssue()
        case Constants.SettingsItemNames.LogOut:
            tapLogOut()
        case Constants.SettingsItemNames.DeleteAccount:
            tapDeleteAccount()
        case Constants.SettingsItemNames.About:
            tapAbout()
        default:
            self.showAlert("Error", message: "Error selecting Side Bar Menu Item.")
        }
    }
    
    func tapTurnOnNotifications() {
        
    }
    
    func reportAnIssue() {
        
    }
    
    func tapLogOut() {
        let alert = UIAlertController(title: "Log Out", message: "Are you sure you want to log out?", preferredStyle: .Alert)
        let yesButton: UIAlertAction = UIAlertAction(title: "Yes", style: .Default) { action in
            let firebaseAuth = FIRAuth.auth()
            do {
                try firebaseAuth?.signOut()
                let logInViewController  = self.storyboard!.instantiateViewControllerWithIdentifier("Log In View Controller") as! LogInViewController
                let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                appDelegate.window?.rootViewController = logInViewController
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