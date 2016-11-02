//
//  NewMessageViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class NewMessageViewController: UIViewController, UITextViewDelegate, SelectSenderDelegate, SelectReceiverDelegate {
    
    @IBOutlet weak var selectSenderButton: UIButton!
    @IBOutlet weak var newButton: UIButton!
    @IBOutlet weak var selectReceiverButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    let api = API.sharedInstance
    let ref = FIRDatabase.database().reference()
    var newMessageViewControllerDelegate: NewMessageViewControllerDelegate!
    var usingNewProxy = false
    
    var sender: Proxy? {
        didSet {
            enableSendButton()
        }
    }
    
    var receiver: Proxy? {
        didSet {
            selectReceiverButton.setTitle(receiver!.key, forState: .Normal)
            enableSendButton()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewMessageViewController.keyboardWillShow), name: UIKeyboardWillShowNotification, object: self.view.window)
        
        navigationItem.title = "New Message"
        
        let cancelButton = UIButton(type: .Custom)
        cancelButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        cancelButton.addTarget(self, action: #selector(NewMessageViewController.cancel), forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.frame = CGRectMake(0, 0, 25, 25)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        if sender != nil {
            setSelectSenderButtonTitle()
        }
        
        messageTextView.becomeFirstResponder()
        messageTextView.delegate = self
        
        sendButton.enabled = false
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo!
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        UIView.animateWithDuration(0.1, animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height + 5
        })
    }
    
    func disableButtons() {
        selectSenderButton.enabled = false
        newButton.enabled = false
        selectReceiverButton.enabled = false
        sendButton.enabled = false
    }
    
    func enableButtons() {
        selectSenderButton.enabled = true
        newButton.enabled = true
        selectReceiverButton.enabled = true
    }
    
    func enableSendButton() {
        if sender != nil && receiver != nil && messageTextView.text != "" {
            sendButton.enabled = true
        } else {
            sendButton.enabled = false
        }
    }
    
    func setSelectSenderButtonTitle() {
        selectSenderButton.setTitle(sender!.key, forState: .Normal)
    }
    
    func setSelectReceiverButtonTitle() {
        selectReceiverButton.setTitle(receiver?.key, forState: .Normal)
    }
    
    // MARK: - Select sender delegate
    func setSender(proxy: Proxy) {
        if usingNewProxy {
            api.delete(proxy: sender!)
            usingNewProxy = false
        }
        sender = proxy
        setSelectSenderButtonTitle()
    }
    
    // MARK: - Select receiver delegate
    func setReceiver(proxy: Proxy) {
        receiver = proxy
        setSelectReceiverButtonTitle()
    }
    
    // MARK: - New proxy
    @IBAction func tapNewButton() {
        disableButtons()
        if !usingNewProxy {
            api.create(proxy: { (proxy) in
                self.setSenderToNewProxy(proxy)
            })
        } else {
            api.delete(proxy: sender!)
            api.create(proxy: { (proxy) in
                self.setSenderToNewProxy(proxy)
            })
        }
    }
    
    func setSenderToNewProxy(proxy: Proxy) {
        sender = proxy
        usingNewProxy = true
        setSelectSenderButtonTitle()
        enableButtons()
    }
    
    // MARK: - Text view
    func textViewDidChange(textView: UITextView) {
        enableSendButton()
    }
    
    // MARK: - Send
    @IBAction func tapSendButton() {
        disableButtons()
        api.sendMessage(sender!, receiver: receiver!, text: messageTextView.text) { (convo) in
            self.goToConvo(convo)
        }
    }
    
    // MARK: - Navigation
    @IBAction func showSelectSenderTableViewController() {
        let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.SelectSenderTableViewController) as! SelectSenderTableViewController
        dest.selectSenderDelegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    @IBAction func showSelectReceiverViewController() {
        let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.SelectReceiverViewController) as! SelectReceiverViewController
        dest.selectReceiverDelegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    func cancel() {
        api.cancelCreatingProxy()
        if usingNewProxy {
            api.delete(proxy: sender!)
        }
        navigationController?.popViewControllerAnimated(true)
    }
    
    func goToConvo(convo: Convo) {
        newMessageViewControllerDelegate.showNewConvo(convo)
        navigationController?.popViewControllerAnimated(true)
    }
}
