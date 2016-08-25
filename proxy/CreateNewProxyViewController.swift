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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.proxyCreated), name: Constants.NotificationKeys.ProxyCreated, object: nil)
        
        setUpUI()
        createProxy()
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
    
    func createProxy() {
        if api.wordBankIsLoaded() == true {
            createProxyFromWordBank()
        } else {
            loadWordBank()
        }
    }
    
    func createProxyFromWordBank() {
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
                    self.createProxyFromWordBank()
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
        disableButtons()
        api.refreshProxyFromOldProxyWithKey(proxyKey)
    }
    
    @IBAction func tapCreateButton(sender: AnyObject) {
        disableButtons()
        let newProxyNickname = newProxyNicknameTextField.text
        if newProxyNickname != "" {
            api.updateNicknameForProxyWithKey(proxyKey, nickname: newProxyNickname!)
        }
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func tapCancelButton(sender: AnyObject) {
        disableButtons()
        if newProxyNameLabel.text != "" {
            api.cancelCreatingProxyWithKey(proxyKey)
        }
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