//
//  CreateNewProxyViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/16/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

class CreateNewProxyViewController: UIViewController, UITextFieldDelegate {
    
    private let api = API.sharedInstance
    private var proxyKey = ""
    private var savingProxy = false
    
    @IBOutlet weak var newProxyNameLabel: UILabel!
    @IBOutlet weak var newProxyNicknameTextField: UITextField!
    @IBOutlet weak var refreshProxyButton: UIButton!
    @IBOutlet weak var createProxyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.proxyCreated), name: Constants.NotificationKeys.ProxyCreated, object: nil)
        setUpUI()
        createProxy()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if newProxyNameLabel.text != "Fetching Proxy..." && !savingProxy {
            api.cancelCreatingProxyWithKey(proxyKey)
        }
    }
    
    func setUpUI() {
        navigationItem.title = "New Proxy"
        newProxyNameLabel.text = "Fetching Proxy..."
        newProxyNicknameTextField.delegate = self
        newProxyNicknameTextField.clearButtonMode = .WhileEditing
        newProxyNicknameTextField.returnKeyType = .Done
        newProxyNicknameTextField.becomeFirstResponder()
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
        let task = session.dataTaskWithRequest(urlRequest) { data, response, error -> Void in
            guard
                let httpResponse = response as? NSHTTPURLResponse
                where httpResponse.statusCode == 200 else {
                    dispatch_async(dispatch_get_main_queue()) {
                        let alert = UIAlertController(title: "Error Fetching Word Bank", message: error!.localizedDescription, preferredStyle: .Alert)
                        let retryAction = UIAlertAction(title: "Retry", style: .Default, handler: { action in
                            self.loadWordBank()
                        })
                        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
                        alert.addAction(retryAction)
                        alert.addAction(cancelAction)
                        self.presentViewController(alert, animated: true, completion: nil)
                    }
                    return
            }
            do {
                let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .AllowFragments)
                if let adjectives = json["adjectives"] as? [String], nouns = json["nouns"] as? [String] {
                    self.api.loadWordBank(adjectives, nouns: nouns)
                    self.createProxyFromWordBank()
                }
            } catch let error as NSError {
                self.showAlert("Error Fetching Word Bank", message: error.localizedDescription)
            }
        }
        task.resume()
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
    
    func saveProxy() {
        disableButtons()
        savingProxy = true
        let newProxyNickname = newProxyNicknameTextField.text
        if newProxyNickname != "" {
            api.saveProxyWithKeyAndNickname(proxyKey, nickname: newProxyNickname!)
        }
        navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction func tapCreateProxyButton(sender: AnyObject) {
        saveProxy()
    }
    
    func disableButtons() {
        refreshProxyButton.enabled = false
        createProxyButton.enabled = false
    }
    
    func enableButtons() {
        refreshProxyButton.enabled = true
        createProxyButton.enabled = true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if createProxyButton.enabled == true {
            saveProxy()
        } else {
            navigationController?.popViewControllerAnimated(true)
        }
        return true
    }
}