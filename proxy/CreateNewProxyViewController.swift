//
//  CreateNewProxyViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/16/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit

class CreateNewProxyViewController: UIViewController {
    
    @IBOutlet weak var newProxyNameLabel: UILabel!
    @IBOutlet weak var newProxyNicknameTextField: UITextField!
    @IBOutlet weak var refreshProxyButton: UIButton!
    @IBOutlet weak var createProxyButton: UIButton!
    @IBOutlet weak var cancelCreateNewProxyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        newProxyNameLabel.text = ""
        newProxyNicknameTextField.clearButtonMode = .WhileEditing
        
        refreshProxyButton.enabled = false
        createProxyButton.enabled = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.proxyCreated), name: Constants.NotificationKeys.ProxyCreated, object: nil)
        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.dismissCreateNewProxyViewController), name: "New Proxy Updated", object: nil)
//        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.dismissCreateNewProxyViewController), name: "New Proxy Deleted", object: nil)
        
        createProxy()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func createProxy() {
        API.sharedInstance.createProxy()
    }
    
    @IBAction func tapRefreshNewProxyButton(sender: AnyObject) {
//        disableButtons()
//        API.sharedInstance.refreshProxyFromOldProxyWithName(newProxyNameLabel.text!)
    }
    
    func proxyCreated(notification: NSNotification) {
//        let userInfo = notification.userInfo as! [String: String]
//        let proxyName = userInfo["proxyName"]!
//        newProxyNameLabel.text = proxyName
//        enableButtons()
    }
    
    @IBAction func tapCreateButton(sender: AnyObject) {
//        disableButtons()
//        if newProxyNicknameTextField.text != "" {
//            API.sharedInstance.updateProxyNickname(newProxyNameLabel.text!, nickname: newProxyNicknameTextField.text!)
//        } else {
//            dismissCreateNewProxyViewController()
//        }
    }
    
    @IBAction func tapCancelButton(sender: AnyObject) {
//        disableButtons()
//        let newProxyName = newProxyNameLabel.text
//        if newProxyName != "" {
//            API.sharedInstance.deleteProxyWithName(newProxyName!)
//        } else {
//            dismissCreateNewProxyViewController()
//        }
    }
    
    func dismissCreateNewProxyViewController() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func disableButtons() {
        cancelCreateNewProxyButton.enabled = false
        refreshProxyButton.enabled = false
        createProxyButton.enabled = false
    }
    
    func enableButtons() {
        cancelCreateNewProxyButton.enabled = true
        refreshProxyButton.enabled = true
        createProxyButton.enabled = true
    }
}