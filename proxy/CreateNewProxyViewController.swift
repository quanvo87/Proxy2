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
    @IBOutlet weak var refreshProxyButton: UIButton!
    @IBOutlet weak var cancelCreateNewProxyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newProxyLabel.text = ""
        refreshProxyButton.enabled = false
        cancelCreateNewProxyButton.enabled = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.getProxyData), name: "Proxy Created", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.cancelReady), name: "Proxy Deleted", object: nil)
        
        createProxy()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func createProxy() {
        ProxyAPI.sharedInstance.createProxy()
    }
    
    func getProxyData(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: String]
        let proxyName = userInfo["proxyName"]!
        newProxyLabel.text = proxyName
        refreshProxyButton.enabled = true
        cancelCreateNewProxyButton.enabled = true
    }
    
    func deleteProxy() {
        if newProxyLabel.text != "" {
            ProxyAPI.sharedInstance.deleteProxyWithName(newProxyLabel.text!)
        }
    }
    
    @IBAction func tapCancelButton(sender: AnyObject) {
        cancelCreateNewProxyButton.enabled = false
        deleteProxy()
    }
    
    func cancelReady() {
        if cancelCreateNewProxyButton.enabled == false {
            dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    @IBAction func tapRefreshNewProxyButton(sender: AnyObject) {
        refreshProxyButton.enabled = false
        deleteProxy()
        createProxy()
    }
    
    @IBAction func tapCreateButton(sender: AnyObject) {
        // update proxy nickname
        dismissViewControllerAnimated(true, completion: nil)
    }
}