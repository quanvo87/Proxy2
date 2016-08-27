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
    
    private var unreadMessages = 0
    
    @IBOutlet weak var myProxiesTableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        setUpTableView()
    }
    
    override func viewDidAppear(animated: Bool) {
        navigationItem.title = "My Proxies (\(unreadMessages))"
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationItem.title = "(\(unreadMessages))"
    }
    
    deinit {
//        ref.child("users").child(uid!).child("proxies").removeObserverWithHandle(userProxiesReferenceHandle)
    }
    
    func setUpUI() {
        
    }
    
    func setUpTableView() {
        automaticallyAdjustsScrollViewInsets = false
        myProxiesTableView.delegate = self
        myProxiesTableView.dataSource = self
        myProxiesTableView.rowHeight = UITableViewAutomaticDimension
        myProxiesTableView.estimatedRowHeight = 80
    }
    
    func configureDatabase() {
//        userProxiesReferenceHandle = ref.child("users").child(uid!).child("proxies").queryOrderedByChild("lastEventTime").observeEventType(.Value, withBlock: { snapshot in
//            print(snapshot)
//            var newProxies = [FIRDataSnapshot]()
//            for child in snapshot.children {
//                newProxies.append(child as! FIRDataSnapshot)
//            }
//            self.proxies = newProxies
//            self.tableView.reloadData()
//        })
    }
    
    @IBAction func tapNewProxyButton(sender: AnyObject) {
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue == "New Proxy Segue" {
            
        }
    }
    
    // MARK: - Table view data source
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Proxy Table View Cell", forIndexPath: indexPath) as! ProxyTableViewCell
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
       
    }
}