//
//  HomeViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private let api = API.sharedInstance
    private let ref = FIRDatabase.database().reference()
    private var userProxiesReferenceHandle = FIRDatabaseHandle()
    private var proxies = [FIRDataSnapshot]()
    
    @IBOutlet weak var menuButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        setUpTableView()
        tryLogin()
    }
    
    override func viewWillAppear(animated: Bool) {
        if navigationItem.title == "" {
            navigationItem.title = "My Proxies"
        }
    }
    
    deinit {
        ref.child("users").child(api.uid).child("proxies").removeObserverWithHandle(userProxiesReferenceHandle)
    }
    
    func setUpUI() {
        menuButton.action = #selector(SWRevealViewController.revealToggle(_:))
        view.addGestureRecognizer(self.revealViewController().panGestureRecognizer())
    }
    
    func setUpTableView() {
        automaticallyAdjustsScrollViewInsets = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 60
    }
    
    func tryLogin() {
        FIRAuth.auth()?.addAuthStateDidChangeListener { auth, user in
            if let user = user {
                self.api.uid = user.uid
                self.configureDatabase()
            } else {
                let logInViewController = self.storyboard!.instantiateViewControllerWithIdentifier("Log In") as! LogInViewController
                self.parentViewController!.presentViewController(logInViewController, animated: true, completion: nil)
            }
        }
    }
    
    func configureDatabase() {
        userProxiesReferenceHandle = ref.child("users").child(api.uid).child("proxies").queryOrderedByChild("lastEventTime").observeEventType(.Value, withBlock: { snapshot in
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
        
        let proxySnapshot = proxies[indexPath.row]
        let proxy = proxySnapshot.value as! Dictionary<String, AnyObject>
        let name = proxy["name"] as! String
        let nickname = proxy["nickname"] as! String
        let lastEvent = proxy["lastEvent"] as! String
        
        cell.proxyNameLabel.text = name
        cell.proxyNicknameLabel.text = nickname == "" ? "" : "- \"" + nickname + "\""
        cell.lastEventLabel.text = lastEvent
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let proxySnapshot = proxies[indexPath.row]
        let proxy = proxySnapshot.value as! Dictionary<String, AnyObject>
        if let proxyViewController = storyboard?.instantiateViewControllerWithIdentifier("Proxy View Controller") as? ProxyViewController {
            proxyViewController.proxy = proxy
            navigationItem.title = ""
            navigationController?.pushViewController(proxyViewController, animated: true)
        }
    }
}