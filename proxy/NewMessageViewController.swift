//
//  NewMessageViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class NewMessageViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, SenderProxyPickerDelegate {
    
    @IBOutlet weak var selectSenderProxyButton: UIButton!
    @IBOutlet weak var newButton: UIButton!
    @IBOutlet weak var selectReceiverProxyButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var delegate: NewMessageViewControllerDelegate!
    var usingNewProxy = false
    
    var senderProxy: Proxy? {
        didSet {
            enableSendButton()
        }
    }
    
    var receiverProxy: Proxy? {
        didSet {
            selectReceiverProxyButton.setTitle(receiverProxy!.key, forState: .Normal)
            enableSendButton()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewMessageViewController.keyboardWillShow), name:UIKeyboardWillShowNotification, object: self.view.window)
        
        navigationItem.title = "New Message"
        messageTextView.becomeFirstResponder()
        messageTextView.delegate = self
        sendButton.enabled = false
        
        if senderProxy != nil {
            setSelectSenderProxyButtonTitle()
        }
        
        let cancelButton = UIButton(type: .Custom)
        cancelButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        cancelButton.addTarget(self, action: #selector(NewMessageViewController.cancelNewMessage), forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.frame = CGRectMake(0, 0, 25, 25)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
    }
    
    func disableButtons() {
        selectSenderProxyButton.enabled = false
        newButton.enabled = false
        selectReceiverProxyButton.enabled = false
        sendButton.enabled = false
    }
    
    func enableButtons() {
        selectSenderProxyButton.enabled = true
        newButton.enabled = true
        selectReceiverProxyButton.enabled = true
    }
    
    func enableSendButton() {
        if senderProxy != nil && receiverProxy != nil && messageTextView.text != "" {
            sendButton.enabled = true
        }
    }
    
    func setSelectSenderProxyButtonTitle() {
        selectSenderProxyButton.setTitle(senderProxy!.key, forState: .Normal)
    }
    
    @IBAction func tapSendButton() {
        disableButtons()
        api.sendMessage(fromSenderProxy: senderProxy!, toReceiverProxyName: receiverProxy!.key, withText: messageTextView.text, withMediaType: "") { (error, convo, message) in
            self.goToConvo(convo!)
        }
    }
    
    // MARK: - Sender proxy picker delegate
    func setSenderProxy(proxy: Proxy) {
        senderProxy = proxy
        setSelectSenderProxyButtonTitle()
    }
    
    // MARK: - New proxy
    @IBAction func tapNewButton() {
        disableButtons()
        if usingNewProxy {
            api.reroll(proxy: senderProxy!, completion: { (proxy) in
                self.setProxy(proxy)
            })
        } else {
            api.create(proxy: { (proxy) in
                self.setProxy(proxy)
                self.usingNewProxy = true
            })
        }
    }
    
    func setProxy(proxy: Proxy?) {
        usingNewProxy = false
        if let proxy = proxy {
            self.senderProxy = proxy
            selectSenderProxyButton.setTitle(proxy.key, forState: .Normal)
        }
        enableButtons()
    }
    
    // MARK: - Text view
    func textViewDidChange(textView: UITextView) { //Handle the text changes here
        enableSendButton()
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
    @IBAction func showSenderProxyPicker() {
        let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.SenderProxyPicker) as! SenderProxyPicker
        dest.delegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    @IBAction func showReceiverProxyPicker() {
        
    }
    
    func cancelNewMessage() {
        api.cancelCreatingProxy()
        navigationController?.popViewControllerAnimated(true)
    }
    
    func goToConvo(convo: Convo) {
        delegate.showNewConvo(convo)
        navigationController?.popViewControllerAnimated(true)
    }
}
