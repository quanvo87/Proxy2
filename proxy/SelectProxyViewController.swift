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
    private var proxies = [Proxy]()
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
        proxiesRef = ref.child("users").child(api.uid).child("proxies")
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
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.Identifiers.ProxyTableViewCell, forIndexPath: indexPath) as! ProxyTableViewCell
        let proxy = self.proxies[indexPath.row]
        cell.titleLabel.text = proxy.name
        cell.subtitleLabel.text = proxy.nickname
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let proxy = self.proxies[indexPath.row]
        delegate.selectProxy(proxy)
        navigationController?.popViewControllerAnimated(true)
    }
}