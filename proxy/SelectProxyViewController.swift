//
//  SelectProxyViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class SelectProxyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var proxiesRef = FIRDatabaseReference()
    var proxiesRefHandle = FIRDatabaseHandle()
    var proxies = [Proxy]()
    var delegate: SelectProxyViewControllerDelegate!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Select A Proxy"
        configureDatabase()
        setUpTableView()
    }
    
    deinit {
        proxiesRef.removeObserverWithHandle(proxiesRefHandle)
    }
    
    func configureDatabase() {
        proxiesRef = ref.child("proxies").child(api.uid)
        proxiesRefHandle = proxiesRef.queryOrderedByChild("timestamp").observeEventType(.Value, withBlock: { snapshot in
            var proxies = [Proxy]()
            for child in snapshot.children {
                let proxy = Proxy(anyObject: child.value)
                proxies.append(proxy)
            }
            self.proxies = proxies.reverse()
            self.tableView.reloadData()
        })
    }
    
    // MARK: - Table view
    
    func setUpTableView() {
        automaticallyAdjustsScrollViewInsets = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ProxyCell, forIndexPath: indexPath) as! ProxyCell
        let proxy = self.proxies[indexPath.row]
        cell.nameLabel.text = proxy.key
        cell.nicknameLabel.text = proxy.nickname
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let proxy = self.proxies[indexPath.row]
        delegate.selectProxy(proxy)
        navigationController?.popViewControllerAnimated(true)
    }
}