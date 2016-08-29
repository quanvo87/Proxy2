//
//  NewMessageViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class NewMessageViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, SelectProxyViewControllerDelegate {
    
    private let api = API.sharedInstance
    private let ref = FIRDatabase.database().reference()
    private var proxy = Proxy()
    private var createdNewProxy = false
    private var savingNewProxy = false
    
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
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewMessageViewController.keyboardWillShow), name:UIKeyboardWillShowNotification, object: self.view.window)
        NSNotificationCenter.defaultCenter().addObserver(self, selector:#selector(NewMessageViewController.proxyCreated), name: Constants.NotificationKeys.ProxyCreated, object: nil)
        
        setUpTextField()
        setUpTextView()
    }
    
    override func viewWillAppear(animated: Bool) {
        navigationItem.title = "New Message"
    }
    
    override func viewWillDisappear(animated: Bool) {
        navigationItem.title = ""
    }
    
    deinit {
        if createdNewProxy && !savingNewProxy {
            api.cancelCreateProxy(proxy)
        }
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        //        disableButtons()
        
        // user must select a proxy to send from
        guard proxy.name != "" else {
            showAlert("Select A Proxy", message: "Please select a proxy to send your message from. Or create a new one!")
            return
        }
        
        // check for empty fields
        guard
            let first = firstTextField.text,
            let second = secondTextField.text,
            let num = numTextField.text,
            let messageText = messageTextView.text
            where first != "" && second != "" && num != "" && messageText != "Message..." else {
                showAlert("Missing Fields", message: "Please enter a value in each field.")
                return
        }
        
        // check if receiver exists
        let receiverName = first.lowercaseString + second.lowercaseString.capitalizedString + num
        self.ref.child("proxies").queryOrderedByKey().queryEqualToValue(receiverName).observeSingleEventOfType(.Value, withBlock: { snapshot in
            guard snapshot.hasChildren() else {
                self.showAlert("Receiving Proxy Not Found", message: "Perhaps there was a spelling error?")
                return
            }
            
            // check if sender is trying to send to him/herself
            var receiverProxy = Proxy(anyObject: snapshot.children.nextObject()!.value)
            guard self.api.uid != receiverProxy.owner else {
                self.showAlert("Cannot Send To Self", message: "Can't start a conversation with you own proxy. Try messaging someone else!")
                return
            }
            
            // check if existing convo between the proxies exists
            let proxies = [self.proxy.name, receiverProxy.name].sort().joinWithSeparator("")
            self.ref.child("convosWith").child(receiverProxy.name).queryOrderedByChild("proxies").queryEqualToValue(proxies).observeSingleEventOfType(.Value, withBlock: { snapshot in
                
                var convoExists = false
                var convosWith = ConvosWith()
                var convosWithKey = ""
                var convo = Convo()
                var convoKey = ""
                
                if snapshot.hasChildren() {
                    
                    // use existing convo
                    convoExists = true
                    convoKey = ConvosWith(anyObject: snapshot.children.nextObject()!.value).convo
                    
                } else {
                    
                    // else make new convo
                    convoKey = self.ref.child("users").child(self.api.uid).child("convos").childByAutoId().key
                    convosWithKey = self.ref.child("users").child(self.api.uid).child("convosWith").childByAutoId().key
                    convosWith = ConvosWith(key: convosWithKey, proxies: proxies, convo: convoKey)
                }
                
                let timestamp = 0 - NSDate().timeIntervalSince1970
                
                // create the message
                let messageKey = self.ref.child("messages").child(convoKey).childByAutoId().key
                let message = Message(key: messageKey, sender: self.api.uid, message: messageText, timestamp: timestamp).toAnyObject()
                
                // update message and timestamp for convos and proxies
                convo.key = convoKey
                convo.message = messageText
                convo.timestamp = timestamp
                let convoDict = convo.toAnyObject()
                
                self.proxy.message = messageText
                self.proxy.timestamp = timestamp
                let proxyDict = self.proxy.toAnyObject()
                
                receiverProxy.message = messageText
                receiverProxy.timestamp = timestamp
                let receiverProxyDict = receiverProxy.toAnyObject()
                
                // save data atomically
                if convoExists {
                    
                    self.ref.updateChildValues([
                        "/messages/\(convoKey)/\(messageKey)": message,
                        "/users/\(self.api.uid)/convos/\(convoKey)": convoDict,
                        "/users/\(receiverProxy.owner)/convos/\(convoKey)": convoDict,
                        "/convos/\(self.proxy.name)/\(convoKey)": convoDict,
                        "/convos/\(receiverProxy.name)/\(convoKey)": convoDict,
                        "/users/\(self.api.uid)/proxies/\(self.proxy.name)": proxyDict,
                        "/users/\(receiverProxy.owner)/proxies/\(receiverProxy.name)": receiverProxyDict,
                        "/proxies/\(self.proxy.name)": proxyDict,
                        "/proxies/\(receiverProxy.name)": receiverProxyDict])
                    
                } else {
                    
                    let senderMemberKey = self.ref.child("members").child(convoKey).childByAutoId().key
                    let receiverMemberKey = self.ref.child("members").child(convoKey).childByAutoId().key
                    let senderMember = Member(key: senderMemberKey, owner: self.api.uid, name: self.proxy.name, nickname: self.proxy.nickname).toAnyObject()
                    let receiverMember = Member(key: receiverMemberKey, owner: receiverProxy.owner, name: receiverProxy.name, nickname: receiverProxy.nickname).toAnyObject()
                    let convosWithDict = convosWith.toAnyObject()
                    
                    self.ref.updateChildValues([
                        "/messages/\(convoKey)/\(messageKey)": message,
                        "/users/\(self.api.uid)/convos/\(convoKey)": convoDict,
                        "/users/\(receiverProxy.owner)/convos/\(convoKey)": convoDict,
                        "/convos/\(self.proxy.name)/\(convoKey)": convoDict,
                        "/convos/\(receiverProxy.name)/\(convoKey)": convoDict,
                        "/users/\(self.api.uid)/proxies/\(self.proxy.name)": proxyDict,
                        "/users/\(receiverProxy.owner)/proxies/\(receiverProxy.name)": receiverProxyDict,
                        "/proxies/\(self.proxy.name)": proxyDict,
                        "/proxies/\(receiverProxy.name)": receiverProxyDict,
                        "/convosWith/\(self.proxy.name)/\(convosWithKey)": convosWithDict,
                        "/convosWith/\(receiverProxy.name)/\(convosWithKey)": convosWithDict,
                        "/members/\(convoKey)/\(senderMemberKey)": senderMember,
                        "/members/\(convoKey)/\(receiverMemberKey)": receiverMember
                        ])
                }
                
                // update unread for receiver user, proxy, and convo
                self.ref.child("users").child(receiverProxy.owner).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                    if var unread = currentData.value as? Int {
                        unread += 1
                        currentData.value = unread
                        return FIRTransactionResult.successWithValue(currentData)
                    }
                    return FIRTransactionResult.successWithValue(currentData)
                }) { (error, committed, snapshot) in
                    if let error = error {
                        self.showAlert("Error Updating Unread Message Count", message: error.localizedDescription)
                    }
                }
                self.ref.child("users").child(receiverProxy.owner).child("proxies").child(receiverProxy.name).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                    if var unread = currentData.value as? Int {
                        unread += 1
                        currentData.value = unread
                        return FIRTransactionResult.successWithValue(currentData)
                    }
                    return FIRTransactionResult.successWithValue(currentData)
                }) { (error, committed, snapshot) in
                    if let error = error {
                        self.showAlert("Error Updating Unread Message Count", message: error.localizedDescription)
                    }
                }
                
                self.ref.child("users").child(receiverProxy.owner).child("convos").child(convoKey).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
                    if var unread = currentData.value as? Int {
                        unread += 1
                        currentData.value = unread
                        return FIRTransactionResult.successWithValue(currentData)
                    }
                    return FIRTransactionResult.successWithValue(currentData)
                }) { (error, committed, snapshot) in
                    if let error = error {
                        self.showAlert("Error Updating Unread Message Count", message: error.localizedDescription)
                    }
                }
                
                // segue to convo
                
            })
        })
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
}