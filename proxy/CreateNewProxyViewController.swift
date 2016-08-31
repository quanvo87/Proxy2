//
//  CreateNewProxyViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/16/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

class CreateNewProxyViewController: UIViewController, UITextFieldDelegate {
    
    private let api = API.sharedInstance
    private var proxy = Proxy()
    private var createdNewProxy = false
    private var savingProxy = false
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var rerollButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewMessageViewController.keyboardWillShow), name:UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(CreateNewProxyViewController.proxyCreated), name: Constants.NotificationKeys.ProxyCreated, object: nil)
        
        setUpUI()
        setUpTextField()
        api.createProxy()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if createdNewProxy && !savingProxy {
            api.cancelCreateProxy(proxy)
        }
    }
    
    func setUpUI() {
        navigationItem.title = "New Proxy"
        nameLabel.text = "Fetching Names..."
        rerollButton.enabled = false
        createButton.enabled = false
    }
    
    func proxyCreated(notification: NSNotification) {
        createdNewProxy = true
        let userInfo = notification.userInfo as! [String: AnyObject]
        proxy = Proxy(anyObject: userInfo["proxy"]!)
        nameLabel.text = proxy.name
        enableButtons()
    }
    
    @IBAction func tapRerollButton(sender: AnyObject) {
        disableButtons()
        api.rerollProxy(proxy)
    }
    
    @IBAction func tapCreateButton(sender: AnyObject) {
        saveProxy()
    }
    
    func saveProxy() {
        disableButtons()
        savingProxy = true
        api.saveProxyWithNickname(proxy, nickname: nicknameTextField.text!)
        navigationController?.popViewControllerAnimated(true)
    }
    
    func disableButtons() {
        rerollButton.enabled = false
        createButton.enabled = false
    }
    
    func enableButtons() {
        rerollButton.enabled = true
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
    
    // MARK: - Keyboard
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height
        })
    }
}