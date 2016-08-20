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
        refreshProxyButton.enabled = false
        createProxyButton.enabled = false
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.getProxyData), name: "New Proxy Created", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.cancelReady), name: "New Proxy Deleted", object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.dismissReady), name: "New Proxy Updated", object: nil)
        
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
        newProxyNameLabel.text = proxyName
        enableButtons()
    }
    
    func deleteProxy() {
        if newProxyNameLabel.text != "" {
            ProxyAPI.sharedInstance.deleteProxyWithName(newProxyNameLabel.text!)
        }
    }
    
    @IBAction func tapCancelButton(sender: AnyObject) {
        disableButtons()
        if newProxyNameLabel.text == "" {
            cancelReady()
        } else {
            deleteProxy()
        }
    }
    
    func cancelReady() {
        if cancelCreateNewProxyButton.enabled == false {
            dismissReady()
        }
    }
    
    @IBAction func tapRefreshNewProxyButton(sender: AnyObject) {
        disableButtons()
        deleteProxy()
        createProxy()
    }
    
    @IBAction func tapCreateButton(sender: AnyObject) {
        disableButtons()
        if newProxyNicknameTextField.text != "" {
            updateProxyNickname(newProxyNameLabel.text!, nickname: newProxyNicknameTextField.text!)
        } else {
            dismissReady()
        }
    }
    
    func updateProxyNickname(proxyName: String, nickname: String) {
        ProxyAPI.sharedInstance.updateProxyNickname(proxyName, nickname: nickname)
    }
    
    func dismissReady() {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    func enableButtons() {
        cancelCreateNewProxyButton.enabled = true
        refreshProxyButton.enabled = true
        createProxyButton.enabled = true
    }
    
    func disableButtons() {
        cancelCreateNewProxyButton.enabled = false
        refreshProxyButton.enabled = false
        createProxyButton.enabled = false
    }
}