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
    @IBOutlet weak var newProxyButton: UIButton!
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
            selectReceiverButton.setTitle(receiver!.key, for: .normal)
            enableSendButton()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "New Message"
        
        let cancelButton = UIButton(type: .custom)
        cancelButton.addTarget(self, action: #selector(NewMessageViewController.cancel), for: UIControlEvents.touchUpInside)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        cancelButton.setImage(UIImage(named: "cancel"), for: UIControlState.normal)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        
        if sender != nil {
            setSelectSenderButtonTitle()
        }
        
        messageTextView.becomeFirstResponder()
        messageTextView.delegate = self
        
        sendButton.isEnabled = false
        
        NotificationCenter.default.addObserver(self, selector: #selector(NewMessageViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: view.window)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        let info = notification.userInfo!
        let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
        UIView.animate(withDuration: 0.1, animations: { () -> Void in
            self.bottomConstraint.constant = keyboardFrame.size.height + 5
        })
    }
    
    func disableButtons() {
        selectSenderButton.isEnabled = false
        newProxyButton.isEnabled = false
        selectReceiverButton.isEnabled = false
        sendButton.isEnabled = false
    }
    
    func enableButtons() {
        selectSenderButton.isEnabled = true
        newProxyButton.isEnabled = true
        selectReceiverButton.isEnabled = true
        enableSendButton()
    }
    
    func enableSendButton() {
        if sender != nil && receiver != nil && messageTextView.text != "" {
            sendButton.isEnabled = true
        } else {
            sendButton.isEnabled = false
        }
    }
    
    func setSelectSenderButtonTitle() {
        selectSenderButton.setTitle(sender!.name, for: .normal)
    }
    
    func setSelectReceiverButtonTitle() {
        selectReceiverButton.setTitle(receiver?.name, for: .normal)
    }
    
    @IBAction func showSelectSenderTableViewController() {
        let dest = self.storyboard?.instantiateViewController(withIdentifier: Identifiers.SenderPickerTableViewController) as! SenderPickerTableViewController
        dest.senderPickerDelegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    @IBAction func tapNewButton() {
        disableButtons()
        if usingNewProxy {
            api.deleteProxy(sender!)
            api.createProxy(completion: { (proxy) in
                self.setSender(toNewProxy: proxy!)
            })
        } else {
            api.createProxy(completion: { (proxy) in
                guard let proxy = proxy else {
                    self.showAlert("Cannot Exceed 50 Proxies", message: "Delete some proxies and try again!")
                    self.enableButtons()
                    return
                }
                self.setSender(toNewProxy: proxy)
            })
        }
    }
    
    func setSender(toNewProxy proxy: Proxy) {
        sender = proxy
        usingNewProxy = true
        setSelectSenderButtonTitle()
        enableButtons()
    }
    
    @IBAction func showSelectReceiverViewController() {
        let dest = self.storyboard?.instantiateViewController(withIdentifier: Identifiers.ReceiverPickerViewController) as! ReceiverPickerViewController
        dest.receiverPickerDelegate = self
        navigationController?.pushViewController(dest, animated: true)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        enableSendButton()
    }
    
    @IBAction func tapSendButton() {
        disableButtons()
        api.sendMessage(sender: sender!, receiver: receiver!, text: messageTextView.text) { (convo) in
            self.newMessageViewControllerDelegate.goToNewConvo(convo)
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc func cancel() {
        api.cancelCreatingProxy()
        if usingNewProxy {
            api.deleteProxy(sender!)
        }
        _ = navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Sender picker delegate
    func setSender(to proxy: Proxy) {
        if usingNewProxy {
            api.deleteProxy(sender!)
            usingNewProxy = false
        }
        sender = proxy
        enableSendButton()
        setSelectSenderButtonTitle()
    }
    
    // MARK: - Receiver picker delegate
    func setReceiver(to proxy: Proxy) {
        receiver = proxy
        setSelectReceiverButtonTitle()
    }
}
