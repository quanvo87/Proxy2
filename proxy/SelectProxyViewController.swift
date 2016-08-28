//
//  SelectProxyViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class SelectProxyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    private let api = API.sharedInstance
    private let ref = FIRDatabase.database().reference()
    private var proxiesRef = FIRDatabaseReference()
    private var proxiesRefHandle = FIRDatabaseHandle()
    private var proxies = [FIRDataSnapshot]()
    
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
        proxiesRef = ref.child("users").child(api.uid).child("proxies")
        proxiesRefHandle = proxiesRef.queryOrderedByChild("timestamp").observeEventType(.Value, withBlock: { snapshot in
            var _proxies = [FIRDataSnapshot]()
            for child in snapshot.children {
                _proxies.append(child as! FIRDataSnapshot)
            }
            self.proxies = _proxies
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
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.ProxyTableViewCell, forIndexPath: indexPath) as! ProxyTableViewCell
        
        let proxy = self.proxies[indexPath.row].value as! [String: AnyObject]
        
        var name = ""
        var nickname = ""
        
        if let _name = proxy[Constants.ProxyFields.Name] {
            name = _name as! String
        }
        if let _nickname = proxy[Constants.ProxyFields.Nickname] {
            nickname = _nickname as! String
        }
        
        cell.nameLabel.text = name
        cell.nicknameLabel.text = nickname.nicknameFormattedWithDash()
        
        return cell
    }
}