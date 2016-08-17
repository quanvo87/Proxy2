//
//  CreateNewProxyViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/16/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit

class CreateNewProxyViewController: UIViewController {
    
    @IBOutlet weak var newProxyLabel: UILabel!
    @IBOutlet weak var nicknameTextField: UITextField!
    var proxy = Proxy()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.useProxyData), name: "Proxy Created", object: nil)
        
        ProxyAPI.sharedInstance.getProxy()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func useProxyData(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        proxy = userInfo["proxy"] as! Proxy
        newProxyLabel.text = proxy.name
    }
    
    @IBAction func tapCancelButton(sender: AnyObject) {
        deleteProxy()
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func tapRefreshNewProxyButton(sender: AnyObject) {
        deleteProxy()
        // get new one
        // enable/disable button
    }
    
    func deleteProxy() {
        ProxyAPI.sharedInstance.deleteProxy(proxy)
    }
    
    @IBAction func tapCreateButton(sender: AnyObject) {
        NSNotificationCenter.defaultCenter().postNotificationName("Proxies Updated", object: self, userInfo: nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}