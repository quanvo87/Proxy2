//
//  MyProxiesViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

class MyProxiesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let uid = FIRAuth.auth()?.currentUser?.uid
    private let ref = FIRDatabase.database().reference()
    private var userProxiesReferenceHandle = FIRDatabaseHandle()
    private var proxies = [FIRDataSnapshot]()
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        setUpTableView()
    }
    
    override func viewWillAppear(animated: Bool) {
        if navigationItem.title == "" {
            navigationItem.title = "My Proxies"
        }
    }
    
    deinit {
//        ref.child("users").child(uid!).child("proxies").removeObserverWithHandle(userProxiesReferenceHandle)
    }
    
    func setUpUI() {
        
    }
    
    func setUpTableView() {
        automaticallyAdjustsScrollViewInsets = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
    }
    
    func configureDatabase() {
        userProxiesReferenceHandle = ref.child("users").child(uid!).child("proxies").queryOrderedByChild("lastEventTime").observeEventType(.Value, withBlock: { snapshot in
            print(snapshot)
            var newProxies = [FIRDataSnapshot]()
            for child in snapshot.children {
                newProxies.append(child as! FIRDataSnapshot)
            }
            self.proxies = newProxies
            self.tableView.reloadData()
        })
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
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
       
    }
}