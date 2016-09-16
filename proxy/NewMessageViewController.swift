//
//  NewMessageViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class NewMessageViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, SelectProxyViewControllerDelegate {
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var proxy: Proxy?
    var createdNewProxy = false
    var savingNewProxy = false
    var delegate: NewMessageViewControllerDelegate!
    
    @IBOutlet weak var selectProxyButton: UIButton!
    @IBOutlet weak var newButton: UIButton!
    @IBOutlet weak var firstTextField: UITextField!
    @IBOutlet weak var secondTextField: UITextField!
    @IBOutlet weak var numTextField: UITextField!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setUpUI()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewMessageViewController.keyboardWillShow), name:UIKeyboardWillShowNotification, object: self.view.window)
        
        setDefaultProxy()
        setUpTextField()
        setUpTextView()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
    }
    
    // MARK: - UI
    
    func setUpUI() {
        navigationItem.title = "New Message"
        setUpCancelButton()
    }
    
    func setUpCancelButton() {
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(NewMessageViewController.closeNewMessage))
        navigationItem.rightBarButtonItem = cancelButton
    }
    
    /*
     If user starts a new message from a proxy info view, load the new message
     view with that proxy pre-selected.
     */
    func setDefaultProxy() {
        if let proxy = proxy {
            selectProxy(proxy)
        }
    }
    
    func disableButtons() {
        selectProxyButton.enabled = false
        newButton.enabled = false
        sendButton.enabled = false
    }
    
    func enableButtons() {
        selectProxyButton.enabled = true
        newButton.enabled = true
        sendButton.enabled = true
    }
    
    @IBAction func tapSendButton(sender: AnyObject) {
        disableButtons()
        
        // Make sure user selected/created a proxy
        guard proxy != nil else {
            enableButtonsAndShowAlert("Select A Proxy", message: "Please select a proxy to send your message from. Or create a new one!")
            return
        }
        
        // Check for empty fields
        guard
            let first = firstTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " ")),
            let second = secondTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " ")),
            let num = numTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " ")),
            let text = messageTextView.text
            where first != "" && second != "" && num != "" && text != "Message..." else {
                enableButtonsAndShowAlert("Missing Fields", message: "Please enter a value for each field.")
                return
        }
        
        // Build receiver proxy name
        let receiverProxyName = first.lowercaseString + second.lowercaseString.capitalizedString + num
        
        // Send off to API to send message
        api.send(messageWithText: text, fromSenderProxy: proxy!, toReceiverProxyName: receiverProxyName) { (error, convo) in
            if let error = error {
                self.enableButtonsAndShowAlert(error.title, message: error.message)
            } else {
                self.api.save(proxy: self.proxy!, withNickname: "")
                self.goToConvo(convo!)
            }
        }
    }
    
    func enableButtonsAndShowAlert(title: String, message: String) {
        enableButtons()
        showAlert(title, message: message)
    }
    
    // MARK: - Select proxy
    
    func selectProxy(proxy: Proxy) {
        if createdNewProxy {
            api.cancelCreating(proxy: proxy)
            savingNewProxy = false
        }
        self.proxy = proxy
        selectProxyButton.setTitle(proxy.key, forState: .Normal)
    }
    
    // MARK: - New proxy
    
    @IBAction func tapNewButton(sender: AnyObject) {
        disableButtons()
        if createdNewProxy {
            api.reroll(fromOldProxy: proxy!, completion: { (proxy) in
                self.setProxy(proxy)
            })
        } else {
            api.create(proxy: { (proxy) in
                self.setProxy(proxy)
            })
        }
    }
    
    func setProxy(proxy: Proxy?) {
        if let proxy = proxy {
            self.proxy = proxy
            selectProxyButton.setTitle(proxy.key, forState: .Normal)
            createdNewProxy = true
            savingNewProxy = true
        }
        enableButtons()
    }
    
    // MARK: - Text field
    
    func setUpTextField() {
        firstTextField.becomeFirstResponder()
        firstTextField.delegate = self
        firstTextField.clearButtonMode = .WhileEditing
        firstTextField.returnKeyType = .Next
        firstTextField.tag = 0
        secondTextField.delegate = self
        secondTextField.clearButtonMode = .WhileEditing
        secondTextField.returnKeyType = .Next
        secondTextField.tag = 1
        numTextField.delegate = self
        numTextField.clearButtonMode = .WhileEditing
        numTextField.returnKeyType = .Next
        numTextField.tag = 2
        numTextField.keyboardType = .NumbersAndPunctuation
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        textField.selectedTextRange = textField.textRangeFromPosition(textField.beginningOfDocument, toPosition: textField.endOfDocument)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let nextTag = textField.tag + 1
        if let nextResponder = textField.superview!.viewWithTag(nextTag){
            nextResponder.becomeFirstResponder()
        } else {
            messageTextView.becomeFirstResponder()
        }
        return false
    }
    
    // MARK: - Text view
    
    func setUpTextView() {
        messageTextView.delegate = self
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        if messageTextView.text == "Message..." {
            messageTextView.text = ""
        }
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        if messageTextView.text == "" {
            messageTextView.text = "Message..."
        }
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
    @IBAction func showSelectProxyViewController(sender: AnyObject) {
        let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.SelectProxyViewController) as! SelectProxyViewController
        dest.delegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    func closeNewMessage() {
//        view.endEditing(true)
        if createdNewProxy && !savingNewProxy {
            api.cancelCreating(proxy: proxy!)
        }
        navigationController?.popViewControllerAnimated(true)
    }
    
    func goToConvo(convo: Convo) {
        delegate.showNewConvo(convo)
        navigationController?.popViewControllerAnimated(true)
    }
}
