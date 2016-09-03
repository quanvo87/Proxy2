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
    var proxy = Proxy()
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
        
        navigationItem.title = "New Message"
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewMessageViewController.keyboardWillShow), name:UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(NewMessageViewController.proxyCreated), name: Constants.NotificationKeys.ProxyCreated, object: nil)
        
        setUp()
        setUpTextField()
        setUpTextView()
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        if createdNewProxy && !savingNewProxy {
            api.cancelCreateProxy(proxy)
        }
    }
    
    func setUp() {
        if proxy.name != "" {
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
        
        // user must select a proxy to send from
        guard proxy.name != "" else {
            enableButtonsAndShowAlert("Select A Proxy", message: "Please select a proxy to send your message from. Or create a new one!")
            return
        }
        
        // check for empty fields
        guard
            let first = firstTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " ")),
            let second = secondTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " ")),
            let num = numTextField.text?.stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: " ")),
            let messageText = messageTextView.text
            where first != "" && second != "" && num != "" && messageText != "Message..." else {
                enableButtonsAndShowAlert("Missing Fields", message: "Please enter a value for each field.")
                return
        }
        
        // check if receiver exists
        let receiverName = first.lowercaseString + second.lowercaseString.capitalizedString + num
        self.ref.child("proxies").queryOrderedByKey().queryEqualToValue(receiverName).observeSingleEventOfType(.Value, withBlock: { snapshot in
            guard snapshot.hasChildren() else {
                self.enableButtonsAndShowAlert("Receiving Proxy Not Found", message: "Perhaps there was a spelling error?")
                return
            }
            
            // check if sender is trying to send to him/herself
            let receiverProxy = Proxy(anyObject: snapshot.children.nextObject()!.value)
            guard self.api.uid != receiverProxy.owner else {
                self.enableButtonsAndShowAlert("Cannot Send To Self", message: "Can't start a conversation with you own proxy. Try messaging someone else!")
                return
            }
            
            // check if existing convo between the proxies exists
            self.ref.child("users").child(self.api.uid).child("convos").observeSingleEventOfType(.Value, withBlock: { snapshot in
                
                for child in snapshot.children {
                    let convo = Convo(anyObject: child.value)
                    if self.proxy.name == convo.senderProxy && receiverProxy.name == convo.receiverProxy {
                        self.api.sendMessage(convo, messageText: messageText, completion: { (success) -> Void in
                            self.goToConvo(convo)
                        })
                        return
                    }
                }
                
                // else make new convo
                self.api.sendFirstMessage(self.proxy, receiverProxy: receiverProxy, messageText: messageText, completion: { (success, convo) in
                    if success {
                        self.goToConvo(convo)
                    } else {
                        self.enableButtons()
                    }
                })
            })
        })
    }
    
    func enableButtonsAndShowAlert(title: String, message: String) {
        enableButtons()
        showAlert(title, message: message)
    }
    
    // MARK: - Select proxy
    
    func selectProxy(proxy: Proxy) {
        if createdNewProxy {
            api.cancelCreateProxy(proxy)
            savingNewProxy = false
        }
        self.proxy = proxy
        selectProxyButton.setTitle(proxy.name, forState: .Normal)
    }
    
    // MARK: - New proxy
    
    @IBAction func tapNewButton(sender: AnyObject) {
        disableButtons()
        if createdNewProxy {
            api.rerollProxy(proxy)
        } else {
            api.createProxy()
        }
    }
    
    func proxyCreated(notification: NSNotification) {
        createdNewProxy = true
        savingNewProxy = true
        let userInfo = notification.userInfo as! [String: AnyObject]
        proxy = Proxy(anyObject: userInfo["proxy"]!)
        selectProxyButton.setTitle(proxy.name, forState: .Normal)
        enableButtons()
    }
    
    // MARK: - Keyboard
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height
        })
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
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.Segues.SelectProxySegue,
            let destination = segue.destinationViewController as? SelectProxyViewController {
            destination.delegate = self
        }
    }
    
    func goToConvo(convo: Convo) {
        delegate.showNewConvo(convo)
        navigationController?.popViewControllerAnimated(true)
    }
}