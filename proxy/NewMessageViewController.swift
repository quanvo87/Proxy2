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
            enableButtonsAndShowAlert("Select A Proxy", message: "Please select a proxy to send your message from. Or create a new one!")
            return
        }
        
        // check for empty fields
        guard
            let first = firstTextField.text,
            let second = secondTextField.text,
            let num = numTextField.text,
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
            var receiverProxy = Proxy(anyObject: snapshot.children.nextObject()!.value)
            
            guard self.api.uid != receiverProxy.owner else {
                self.enableButtonsAndShowAlert("Cannot Send To Self", message: "Can't start a conversation with you own proxy. Try messaging someone else!")
                return
            }
            
            // check if existing convo between the proxies exists
            let members = [self.proxy.name, receiverProxy.name].sort().joinWithSeparator(", ")
            self.ref.child("users").child(receiverProxy.owner).child("convos").observeSingleEventOfType(.Value, withBlock: { snapshot in
                
                var convo = Convo()
                var convoExists = false
                
                for child in snapshot.children {
                    let _convo = Convo(anyObject: child.value)
                    if _convo.members == members {
                        convo = _convo
                        convoExists = true
                        break
                    }
                }
                
                // use existing convo
                if convoExists {
                    
                    let timestamp = 0 - NSDate().timeIntervalSince1970
                    
                    // create the message
                    let messageKey = self.ref.child("messages").child(convo.key).childByAutoId().key
                    let message = Message(key: messageKey, sender: self.api.uid, message: messageText, timestamp: timestamp).toAnyObject()
                    
                    // update message and timestamp for convos and proxies
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
                    let update = [
                        "/messages/\(convo.key)/\(messageKey)": message,
                        "/users/\(self.api.uid)/convos/\(convo.key)": convoDict,
                        "/users/\(receiverProxy.owner)/convos/\(convo.key)": convoDict,
                        "/convos/\(self.proxy.name)/\(convo.key)": convoDict,
                        "/convos/\(receiverProxy.name)/\(convo.key)": convoDict,
                        "/users/\(self.api.uid)/proxies/\(self.proxy.name)": proxyDict,
                        "/users/\(receiverProxy.owner)/proxies/\(receiverProxy.name)": receiverProxyDict,
                        "/proxies/\(self.proxy.name)": proxyDict,
                        "/proxies/\(receiverProxy.name)": receiverProxyDict]
                    
                    self.ref.updateChildValues(update, withCompletionBlock: { (error, ref) in
                        self.updateUnreadForReceiver(receiverProxy, convoKey: convo.key)
                    })
                    
                } else {
                    
                    // else make new convo
                    let convoKey = self.ref.child("users").child(self.api.uid).child("convos").childByAutoId().key
                    
                    let timestamp = 0 - NSDate().timeIntervalSince1970
                    
                    // create the message
                    let messageKey = self.ref.child("messages").child(convoKey).childByAutoId().key
                    let message = Message(key: messageKey, sender: self.api.uid, message: messageText, timestamp: timestamp).toAnyObject()
                    
                    // update message and timestamp for convos and proxies
                    convo.key = convoKey
                    convo.message = messageText
                    convo.timestamp = timestamp
                    convo.members = members
                    let convoDict = convo.toAnyObject()
                    
                    self.proxy.message = messageText
                    self.proxy.timestamp = timestamp
                    let proxyDict = self.proxy.toAnyObject()
                    
                    receiverProxy.message = messageText
                    receiverProxy.timestamp = timestamp
                    let receiverProxyDict = receiverProxy.toAnyObject()
                    
                    let senderMemberKey = self.ref.child("members").child(convoKey).childByAutoId().key
                    let receiverMemberKey = self.ref.child("members").child(convoKey).childByAutoId().key
                    let senderMember = Member(key: senderMemberKey, owner: self.api.uid, name: self.proxy.name, nickname: self.proxy.nickname).toAnyObject()
                    let receiverMember = Member(key: receiverMemberKey, owner: receiverProxy.owner, name: receiverProxy.name, nickname: receiverProxy.nickname).toAnyObject()
                    
                    // save data atomically
                    let update = [
                        "/messages/\(convoKey)/\(messageKey)": message,
                        "/users/\(self.api.uid)/convos/\(convoKey)": convoDict,
                        "/users/\(receiverProxy.owner)/convos/\(convoKey)": convoDict,
                        "/convos/\(self.proxy.name)/\(convoKey)": convoDict,
                        "/convos/\(receiverProxy.name)/\(convoKey)": convoDict,
                        "/users/\(self.api.uid)/proxies/\(self.proxy.name)": proxyDict,
                        "/users/\(receiverProxy.owner)/proxies/\(receiverProxy.name)": receiverProxyDict,
                        "/proxies/\(self.proxy.name)": proxyDict,
                        "/proxies/\(receiverProxy.name)": receiverProxyDict,
                        "/members/\(convoKey)/\(senderMemberKey)": senderMember,
                        "/members/\(convoKey)/\(receiverMemberKey)": receiverMember]
                    
                    self.ref.updateChildValues(update, withCompletionBlock: { (error, ref) in
                        self.updateUnreadForReceiver(receiverProxy, convoKey: convo.key)
                    })
                }
                
                // segue to convo
                
            })
        })
    }
    
    func enableButtonsAndShowAlert(title: String, message: String) {
        enableButtons()
        showAlert(title, message: message)
    }
    
    func updateUnreadForReceiver(receiverProxy: Proxy, convoKey: String) {
        
        self.ref.child("users").child(receiverProxy.owner).child("unread").runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread + 1
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print("Error Updating Unread Message Count: \(error.localizedDescription)")
            }
        }
        
        self.ref.child("unread").child(receiverProxy.owner).child(convoKey).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread + 1
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print("Error Updating Unread Message Count: \(error.localizedDescription)")
            }
        }
        
        self.ref.child("unread").child(receiverProxy.owner).child(receiverProxy.name).runTransactionBlock({ (currentData: FIRMutableData) -> FIRTransactionResult in
            if let unread = currentData.value {
                let _unread = unread as? Int ?? 0
                currentData.value = _unread + 1
                return FIRTransactionResult.successWithValue(currentData)
            }
            return FIRTransactionResult.successWithValue(currentData)
        }) { (error, committed, snapshot) in
            if let error = error {
                print("Error Updating Unread Message Count: \(error.localizedDescription)")
            }
        }
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