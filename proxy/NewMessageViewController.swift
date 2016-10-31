//
//  NewMessageViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class NewMessageViewController: UIViewController, UITextViewDelegate, SenderProxyPickerDelegate {
    
    @IBOutlet weak var selectSenderProxyButton: UIButton!
    @IBOutlet weak var newButton: UIButton!
    @IBOutlet weak var selectReceiverProxyButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var newMessageViewControllerDelegate: NewMessageViewControllerDelegate!
    var isUsingNewProxy = false
    
    var sender: Proxy? {
        didSet {
            enableSendButton()
        }
    }
    
    var receiver: Proxy? {
        didSet {
            selectReceiverProxyButton.setTitle(receiver!.key, forState: .Normal)
            enableSendButton()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewMessageViewController.keyboardWillShow), name:UIKeyboardWillShowNotification, object: self.view.window)
        
        navigationItem.title = "New Message"
        
        let cancelButton = UIButton(type: .Custom)
        cancelButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        cancelButton.addTarget(self, action: #selector(NewMessageViewController.cancelNewMessage), forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.frame = CGRectMake(0, 0, 25, 25)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        if sender != nil {
            setSelectSenderProxyButtonTitle()
        }
        
        messageTextView.becomeFirstResponder()
        messageTextView.delegate = self
        sendButton.enabled = false
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
        if sender != nil && receiver != nil && sender?.key != receiver?.key && messageTextView.text != "" {
            sendButton.enabled = true
        }
    }
    
    func setSelectSenderProxyButtonTitle() {
        selectSenderProxyButton.setTitle(sender!.key, forState: .Normal)
    }
    
    @IBAction func tapSendButton() {
        disableButtons()
        api.sendMessage(sender!, receiver: receiver!, text: messageTextView.text) { (convo) in
            self.goToConvo(convo)
        }
    }
    
    // MARK: - Sender proxy picker delegate
    func setSenderProxy(proxy: Proxy) {
        sender = proxy
        setSelectSenderProxyButtonTitle()
    }
    
    // MARK: - New proxy
    @IBAction func tapNewButton() {
        disableButtons()
        if isUsingNewProxy {
            api.reroll(proxy: sender!, completion: { (proxy) in
                self.setProxy(proxy)
            })
        } else {
            api.create(proxy: { (proxy) in
                self.setProxy(proxy)
                self.isUsingNewProxy = true
            })
        }
    }
    
    func setProxy(proxy: Proxy?) {
        isUsingNewProxy = false
        if let proxy = proxy {
            self.sender = proxy
            selectSenderProxyButton.setTitle(proxy.key, forState: .Normal)
        }
        enableButtons()
    }
    
    // MARK: - Text view
    func textViewDidChange(textView: UITextView) {
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
        newMessageViewControllerDelegate.showNewConvo(convo)
        navigationController?.popViewControllerAnimated(true)
    }
}
