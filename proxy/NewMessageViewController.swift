//
//  NewMessageViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class NewMessageViewController: UIViewController, UITextViewDelegate, SelectSenderDelegate {
    
    @IBOutlet weak var selectSenderButton: UIButton!
    @IBOutlet weak var newButton: UIButton!
    @IBOutlet weak var selectReceiverButton: UIButton!
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
        cancelButton.addTarget(self, action: #selector(NewMessageViewController.cancelNewMessage), forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.frame = CGRectMake(0, 0, 25, 25)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        if sender != nil {
            setSelectSenderButtonTitle()
        }
        
        messageTextView.becomeFirstResponder()
        messageTextView.delegate = self
        
        sendButton.enabled = false
        sendButton.layer.cornerRadius = 5
        sendButton.layer.borderWidth = 1
        sendButton.layer.borderColor = UIColor.lightGrayColor().CGColor
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
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
        if sender != nil && receiver != nil && sender?.key != receiver?.key && messageTextView.text != "" {
            sendButton.enabled = true
        }
    }
    
    func setSelectSenderButtonTitle() {
        selectSenderButton.setTitle(sender!.key, forState: .Normal)
    }
    
    @IBAction func tapSendButton() {
        disableButtons()
        api.sendMessage(sender!, receiver: receiver!, text: messageTextView.text) { (convo) in
            self.goToConvo(convo)
        }
    }
    
    // MARK: - Select sender delegate
    func setSender(proxy: Proxy) {
        sender = proxy
        setSelectSenderButtonTitle()
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
            selectSenderButton.setTitle(proxy.key, forState: .Normal)
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
            self.bottomConstraint.constant = keyboardFrame.size.height + 5
        })
    }
    
    // MARK: - Navigation
    @IBAction func showSelectSenderTableViewController() {
        let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.SelectSenderTableViewController) as! SelectSenderTableViewController
        dest.selectSenderDelegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    @IBAction func showSelectReceiverViewController() {
        let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.SelectReceiverViewController) as! SelectReceiverViewController
        navigationController?.pushViewController(dest, animated: true)
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
