//
//  CreateNewProxyViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/16/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

class CreateNewProxyViewController: UIViewController, UITextFieldDelegate {
    
    private let api = API.sharedInstance
    private var key = ""
    private var save = false
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.proxyCreated), name: Constants.NotificationKeys.ProxyCreated, object: nil)
        
        setUpUI()
        setUpTextField()
        createProxy()
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if nameLabel.text != "Fetching Proxy..." && !save {
            api.cancelCreatingProxyWithKey(key)
        }
    }
    
    func setUpUI() {
        navigationItem.title = "New Proxy"
        nameLabel.text = "Fetching Proxy..."
        refreshButton.enabled = false
        createButton.enabled = false
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
                if let adjs = json["adjectives"] as? [String], nouns = json["nouns"] as? [String] {
                    self.api.loadWordBank(adjs, nouns: nouns)
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
        nameLabel.text = proxy["name"] as? String
        key = proxy["key"] as! String
        enableButtons()
    }
    
    @IBAction func tapRefreshButton(sender: AnyObject) {
        disableButtons()
        api.refreshProxyFromOldProxyWithKey(key)
    }
    
    @IBAction func tapCreateButton(sender: AnyObject) {
        saveProxy()
    }
    
    func saveProxy() {
        disableButtons()
        save = true
        let newProxyNickname = nicknameTextField.text
        if newProxyNickname != "" {
            api.saveProxyWithKeyAndNickname(key, nickname: newProxyNickname!)
        }
        navigationController?.popViewControllerAnimated(true)
    }
    
    func disableButtons() {
        refreshButton.enabled = false
        createButton.enabled = false
    }
    
    func enableButtons() {
        refreshButton.enabled = true
        createButton.enabled = true
    }
    
    // MARK: - Text field
    
    func setUpTextField() {
        nicknameTextField.delegate = self
        nicknameTextField.clearButtonMode = .WhileEditing
        nicknameTextField.returnKeyType = .Done
        nicknameTextField.becomeFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if createButton.enabled == true {
            saveProxy()
        } else {
            navigationController?.popViewControllerAnimated(true)
        }
        return true
    }
}