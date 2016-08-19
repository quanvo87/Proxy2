//
//  HomeViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/14/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var homeTableView: UITableView!
    var proxies = [Proxy]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "My Proxies"
        
        automaticallyAdjustsScrollViewInsets = false
        
        homeTableView.delegate = self
        homeTableView.dataSource = self
        homeTableView.rowHeight = UITableViewAutomaticDimension
        homeTableView.estimatedRowHeight = 60
    }
    
    override func viewWillAppear(animated: Bool) {
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(HomeViewController.loadTable), name: "Proxies Fetched", object: nil)
        getProxies()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func getProxies() {
        ProxyAPI.sharedInstance.getProxies()
    }
    
    func loadTable(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: [Proxy]]
        proxies = userInfo["proxies"]!
        homeTableView.reloadData()
    }
    
    @IBAction func tapCreateNewProxy(sender: AnyObject) {
        if let createNewProxyViewController = storyboard?.instantiateViewControllerWithIdentifier("Create New Proxy") as! CreateNewProxyViewController? {
            self.presentViewController(createNewProxyViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return proxies.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Home Table View Cell", forIndexPath: indexPath) as! HomeTableViewCell
        let proxy = proxies[indexPath.row]
        cell.proxyNameLabel.text = proxy.name
        cell.proxyNicknameLabel.text = proxy.nickname
        cell.lastEventMessageLabel.text = proxy.lastEventMessage
        return cell
    }
}