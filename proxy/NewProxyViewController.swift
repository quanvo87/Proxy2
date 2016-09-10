//
//  NewProxyViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/16/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

class NewProxyViewController: UIViewController, UITextFieldDelegate {
    
    let api = API.sharedInstance
    var proxy: Proxy?
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var nicknameTextField: UITextField!
    @IBOutlet weak var rerollButton: UIButton!
    @IBOutlet weak var createButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewMessageViewController.keyboardWillShow), name:UIKeyboardWillShowNotification, object: self.view.window)
        
        setUpUI()
        setUpTextField()
        createProxy()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
    }
    
    func setUpUI() {
        navigationItem.title = "New Proxy"
        nameLabel.text = "Fetching Names..."
    }
    
    func createProxy() {
        disableButtons()
        api.create { (proxy) in
            self.setProxy(proxy)
        }
    }
    
    @IBAction func tapRerollButton(sender: AnyObject) {
        disableButtons()
        api.reroll(fromOldProxy: proxy!) { (proxy) in
            self.setProxy(proxy)
        }
    }
    
    func setProxy(proxy: Proxy?) {
        self.enableButtons()
        if let proxy = proxy {
            self.proxy = proxy
            self.nameLabel.text = proxy.key
        }
    }
    
    @IBAction func tapCreateButton(sender: AnyObject) {
        saveProxy()
    }
    
    func saveProxy() {
        disableButtons()
        api.save(proxy: proxy!, withNickname: nicknameTextField.text!)
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
    
    // MARK: - Navigation
    
    @IBAction func tapCancelButton(sender: AnyObject) {
        view.endEditing(true)
        if let proxy = proxy {
            api.cancelCreating(proxy)
        }
        navigationController?.popViewControllerAnimated(true)
    }
}