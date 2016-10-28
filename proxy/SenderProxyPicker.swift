//
//  SenderProxyPicker.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class SenderProxyPicker: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var proxiesRef = FIRDatabaseReference()
    var proxiesRefHandle = FIRDatabaseHandle()
    var proxies = [Proxy]()
    var delegate: SenderProxyPickerDelegate!
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUp()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        observeProxies()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(true)
        proxiesRef.removeObserverWithHandle(proxiesRefHandle)
    }
    
    func setUp() {
        navigationItem.title = "Select Sender Proxy"
        automaticallyAdjustsScrollViewInsets = false
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 80
        tableView.estimatedRowHeight = 80
        proxiesRef = ref.child(Path.Proxies).child(api.uid)
    }
    
    func observeProxies() {
        proxiesRefHandle = proxiesRef.queryOrderedByChild(Path.Timestamp).observeEventType(.Value, withBlock: { snapshot in
            var proxies = [Proxy]()
            for child in snapshot.children {
                let proxy = Proxy(anyObject: child.value)
                proxies.append(proxy)
            }
            self.proxies = proxies.reverse()
            self.tableView.reloadData()
        })
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(Identifiers.ProxyCell, forIndexPath: indexPath) as! ProxyCell
        let proxy = self.proxies[indexPath.row]
        cell.nameLabel.text = proxy.key
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let proxy = self.proxies[indexPath.row]
        delegate.setSenderProxy(proxy)
        navigationController?.popViewControllerAnimated(true)
    }
}
