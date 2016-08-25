//
//  CreateNewProxyViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/16/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit

class CreateNewProxyViewController: UIViewController {
    
    let api = API.sharedInstance
    private var proxyKey = ""
    
    @IBOutlet weak var newProxyNameLabel: UILabel!
    @IBOutlet weak var newProxyNicknameTextField: UITextField!
    @IBOutlet weak var refreshProxyButton: UIButton!
    @IBOutlet weak var createProxyButton: UIButton!
    @IBOutlet weak var cancelCreateNewProxyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.createProxy), name: Constants.NotificationKeys.WordBankLoaded, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.proxyCreated), name: Constants.NotificationKeys.ProxyCreated, object: nil)
        
        setUpUI()
        tryCreateProxy()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func setUpUI() {
        newProxyNameLabel.text = ""
        newProxyNicknameTextField.clearButtonMode = .WhileEditing
        refreshProxyButton.enabled = false
        createProxyButton.enabled = false
    }
    
    func tryCreateProxy() {
        if api.wordBankIsLoaded() == true {
            createProxy()
        } else {
            loadWordBank()
        }
    }
    
    func createProxy() {
        api.currentlyCreatingProxy = true
        api.createProxy()
    }
    
    func loadWordBank() {
        let url = NSURL(string: "https://api.myjson.com/bins/4xqqn")!
        let urlRequest = NSMutableURLRequest(URL: url)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest) {
            (data, response, error) -> Void in
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            if statusCode == 200 {
                do {
                    var adjectives = [String]()
                    var nouns = [String]()
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                    if let fetchedAdjectives = json["adjectives"] as? [String] {
                        adjectives = fetchedAdjectives
                    }
                    if let fetchedNouns = json["nouns"] as? [String] {
                        nouns = fetchedNouns
                    }
                    self.api.loadWordBank(adjectives, nouns: nouns)
                    NSNotificationCenter.defaultCenter().postNotificationName(Constants.NotificationKeys.WordBankLoaded, object: self, userInfo: nil)
                } catch {
                    self.showAlert("Error Fetching Word Bank", message: "Please try again later.")
                }
            } else {
                self.showRetryLoadWordBank("Error Fetching Word Bank", message: (error?.localizedDescription)!)
            }
        }
        task.resume()
    }
    
    func showRetryLoadWordBank(title: String, message: String) {
        dispatch_async(dispatch_get_main_queue()) {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
            let retryAction = UIAlertAction(title: "Retry", style: .Default, handler: { action in
                
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
            alert.addAction(retryAction)
            alert.addAction(cancelAction)
            self.presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func proxyCreated(notification: NSNotification) {
        let userInfo = notification.userInfo as! [String: AnyObject]
        let proxy = userInfo["proxy"]!
        newProxyNameLabel.text = proxy["name"] as? String
        proxyKey = proxy["key"] as! String
        enableButtons()
    }
    
    @IBAction func tapRefreshNewProxyButton(sender: AnyObject) {
        //        disableButtons()
        //        API.sharedInstance.refreshProxyFromOldProxyWithName(newProxyNameLabel.text!)
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