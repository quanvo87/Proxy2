//
//  HomeViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let ref = FIRDatabase.database().reference()
    private var userProxiesReferenceHandle = FIRDatabaseHandle()
    private var uid = ""
    private var proxies = [Proxy]()
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var homeTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tryLogin()
        automaticallyAdjustsScrollViewInsets = false
    }

    deinit {
        ref.child("users").child(uid).child("proxies").removeObserverWithHandle(userProxiesReferenceHandle)
    }
    
    func tryLogin() {
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let user = user {
                self.uid = user.uid
                self.setUpUI()
                self.setUpTableView()
                self.configureDatabase()
            } else {
                let logInViewController = self.storyboard!.instantiateViewControllerWithIdentifier("Log In") as! LogInViewController
                self.parentViewController!.presentViewController(logInViewController, animated: true, completion: nil)
            }
        }
    }
    
    func setUpUI() {
        self.navigationItem.title = "My Proxies"
        self.menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        self.view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
    }
    
    func setUpTableView() {
        homeTableView.delegate = self
        homeTableView.dataSource = self
        homeTableView.rowHeight = UITableViewAutomaticDimension
        homeTableView.estimatedRowHeight = 60
    }
    
    func configureDatabase() {
//        userProxiesReferenceHandle = ref.child("users").child(uid).child("proxies").queryOrderedByChild("lastEventTime").observeEventType(.Value, withBlock: { snapshot in
//            var newProxies = [Proxy]()
//            for item in snapshot.children {
//                let proxy = Proxy(snapshot: item as! FIRDataSnapshot)
//                newProxies.append(proxy)
//            }
//            self.proxies = newProxies
//            self.homeTableView.reloadData()
//        })
    }
    
    @IBAction func tapCreateNewProxy(sender: AnyObject) {
        if let createNewProxyViewController = storyboard?.instantiateViewControllerWithIdentifier("Create New Proxy") as! CreateNewProxyViewController? {
            self.presentViewController(createNewProxyViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Home Table View Cell", forIndexPath: indexPath) as! HomeTableViewCell
//        let proxy = proxies[indexPath.row]
//        cell.proxyNameLabel.text = proxy.name
//        cell.proxyNicknameLabel.text = proxy.nickname
//        cell.lastEventMessageLabel.text = proxy.lastEventMessage
        return cell
    }
}