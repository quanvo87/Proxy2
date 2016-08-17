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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.useProxyData), name: "Proxy Created", object: nil)
        
        createProxy()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func createProxy() {
        ProxyAPI.sharedInstance.createProxy()
    }
    
    func useProxyData(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: Proxy]
        let proxy = userInfo["proxy"]!
        newProxyLabel.text = proxy.name
    }
    
    func deleteProxy() {
        if let proxyName = newProxyLabel.text {
//            ProxyAPI.sharedInstance.deleteProxyWithName(proxyName)
        }
    }
    
    @IBAction func tapCancelButton(sender: AnyObject) {
        deleteProxy()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func tapRefreshNewProxyButton(sender: AnyObject) {
        deleteProxy()
        createProxy()
        // enable/disable button
    }
    
    @IBAction func tapCreateButton(sender: AnyObject) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}