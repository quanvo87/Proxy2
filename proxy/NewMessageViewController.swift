//
//  NewMessageViewController.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseDatabase

class NewMessageViewController: UIViewController, UITextViewDelegate, SenderPickerDelegate, ReceiverPickerDelegate {
    
    @IBOutlet weak var selectSenderButton: UIButton!
    @IBOutlet weak var newButton: UIButton!
    @IBOutlet weak var selectReceiverButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    let api = API.sharedInstance
    var newMessageViewControllerDelegate: NewMessageViewControllerDelegate!
    var usingNewProxy = false
    var sender: Proxy?
    var receiver: Proxy? {
        didSet {
            selectReceiverButton.setTitle(receiver!.key, forState: .Normal)
            enableSendButton()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "New Message"
        
        let cancelButton = UIButton(type: .Custom)
        cancelButton.addTarget(self, action: #selector(NewMessageViewController.cancel), forControlEvents: UIControlEvents.TouchUpInside)
        cancelButton.frame = CGRectMake(0, 0, 25, 25)
        cancelButton.setImage(UIImage(named: "cancel"), forState: UIControlState.Normal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        if sender != nil {
            setSelectSenderButtonTitle()
        }
        
        messageTextView.becomeFirstResponder()
        messageTextView.delegate = self
        
        sendButton.enabled = false
        
        NotificationCenter.defaultCenter().addObserver(self, selector: #selector(NewMessageViewController.keyboardWillShow), name: UIKeyboardWillShowNotification, object: view.window)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func keyboardWillShow(_ notification: Notification) {
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
        enableSendButton()
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
    
    @IBAction func showSelectSenderTableViewController() {
        let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.SenderPickerTableViewController) as! SenderPickerTableViewController
        dest.senderPickerDelegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    @IBAction func tapNewButton() {
        disableButtons()
        if usingNewProxy {
            api.delete(proxy: sender!)
            api.create(proxy: { (proxy) in
                self.setSenderToNewProxy(proxy!)
            })
        } else {
            api.create(proxy: { (proxy) in
                guard let proxy = proxy else {
                    self.showAlert("Cannot Exceed 50 Proxies", message: "Delete some proxies and try again!")
                    self.enableButtons()
                    return
                }
                self.setSenderToNewProxy(proxy)
            })
        }
    }
    
    func setSenderToNewProxy(_ proxy: Proxy) {
        sender = proxy
        usingNewProxy = true
        setSelectSenderButtonTitle()
        enableButtons()
    }
    
    @IBAction func showSelectReceiverViewController() {
        let dest = self.storyboard?.instantiateViewControllerWithIdentifier(Identifiers.ReceiverPickerViewController) as! ReceiverPickerViewController
        dest.receiverPickerDelegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        enableSendButton()
    }
    
    @IBAction func tapSendButton() {
        disableButtons()
        api.sendMessage(sender!, receiver: receiver!, text: messageTextView.text) { (convo) in
            self.newMessageViewControllerDelegate.goToNewConvo(convo)
            self.navigationController?.popViewControllerAnimated(true)
        }
    }
    
    func cancel() {
        api.cancelCreatingProxy()
        if usingNewProxy {
            api.delete(proxy: sender!)
        }
        navigationController?.popViewControllerAnimated(true)
    }
    
    // MARK: - Sender picker delegate
    func setSender(_ proxy: Proxy) {
        if usingNewProxy {
            api.delete(proxy: sender!)
            usingNewProxy = false
        }
        sender = proxy
        enableSendButton()
        setSelectSenderButtonTitle()
    }
    
    // MARK: - Receiver picker delegate
    func setReceiver(_ proxy: Proxy) {
        receiver = proxy
        setSelectReceiverButtonTitle()
    }
}
