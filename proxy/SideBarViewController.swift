//
//  SideBarViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/20/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit
import FacebookLogin

class SideBarViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var sideBarTableView: UITableView!
    var sideBarItems = [SideBarItem]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sideBarItems = SideBarItems().getSideBarItems()
        
        sideBarTableView.delegate = self
        sideBarTableView.dataSource = self
        sideBarTableView.reloadData()
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
        case "Suggest A Word!":
            tapSuggestAWord()
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
        
    }
    
    func tapTurnOnNotifications() {
        
    }
    
    func tapTrash() {
        
    }
    
    func tapSuggestAWord() {
        
    }
    
    func tapLogOut() {
        let alert = UIAlertController(title: "", message: "Are you sure you want to log out?", preferredStyle: .Alert)
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
        let loginManager = LoginManager()
        loginManager.logOut()
        
        KCSUser.activeUser().logout()
        
        if let signUpViewController = storyboard?.instantiateViewControllerWithIdentifier("Sign Up") as! SignUpViewController? {
            self.presentViewController(signUpViewController, animated: true, completion: nil)
        }
    }
    
    func tapDeleteAccount() {
        
    }
    
    func tapAbout() {
        
    }
    
    //    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    //        let post = posts[indexPath.section]
    //        let flags = post["flags"] as! Int
    //        if flags < 3 {
    //            showPostDetail(post)
    //        } else {
    //            self.showAlert("This post has been flagged as inappropriate and is now closed.")
    //            getPosts()
    //        }
    //    }
    //
    //    func showPostDetail(post: PFObject) {
    //        if let postDetailViewController = storyboard?.instantiateViewControllerWithIdentifier("Post Detail") as! PostDetailViewController? {
    //            postDetailViewController.post = post
    //            navigationItem.title = "Home"
    //            navigationController?.pushViewController(postDetailViewController, animated: true)
    //        }
    //    }
}