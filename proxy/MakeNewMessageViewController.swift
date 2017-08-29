import FirebaseDatabase

class MakeNewMessageViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var makeNewProxyButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var pickReceiverButton: UIButton!
    @IBOutlet weak var pickSenderButton: UIButton!
    @IBOutlet weak var sendMessageButton: UIButton!

    var delegate: MakeNewMessageViewControllerDelegate?
    var receiver: Proxy? {
        didSet {
            pickReceiverButton.setTitle(receiver?.name, for: .normal)
            enableButtons()
        }
    }
    var sender: Proxy? {
        didSet {
            pickSenderButton.setTitle(sender?.name, for: .normal)
            enableButtons()
        }
    }
    var senderIsNewProxy = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let cancelButton = UIButton(type: .custom)
        cancelButton.addTarget(self, action: #selector(MakeNewMessageViewController.cancelMakingNewMessage), for: .touchUpInside)
        cancelButton.frame = CGRect(x: 0, y: 0, width: 25, height: 25)
        cancelButton.setImage(UIImage(named: "cancel"), for: .normal)

        messageTextView.becomeFirstResponder()
        messageTextView.delegate = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelButton)
        navigationItem.title = "New Message"

        NotificationCenter.default.addObserver(self, selector: #selector(MakeNewMessageViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: view.window)

        sendMessageButton.isEnabled = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        navigationItem.hidesBackButton = true
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension MakeNewMessageViewController {
    @IBAction func goToReceiverPickerViewController() {
        if let receiverPickerVC = storyboard?.instantiateViewController(withIdentifier: Identifier.ReceiverPickerViewController) as? ReceiverPickerViewController {
            receiverPickerVC.delegate = self
            navigationController?.pushViewController(receiverPickerVC, animated: true)
        }
    }

    @IBAction func goToSenderPickerTableViewController() {
        if let senderPickerVC = self.storyboard?.instantiateViewController(withIdentifier: Identifier.SenderPickerTableViewController) as? SenderPickerTableViewController {
            senderPickerVC.delegate = self
            navigationController?.pushViewController(senderPickerVC, animated: true)
        }
    }

    @IBAction func tapMakeNewProxyButton() {
        disableButtons()
        if let sender = sender, senderIsNewProxy {
            DBProxy.deleteProxy(sender) { (success) in
                guard success else {
                    self.enableButtons()
                    return
                }
                self.senderIsNewProxy = false
                self.makeNewProxy()
            }
        } else {
            makeNewProxy()
        }
    }

    @IBAction func tapSendMessageButton() {
        disableButtons()
        guard let sender = sender, let receiver = receiver else {
            enableButtons()
            return
        }
        DBMessage.sendMessage(from: sender, to: receiver, withText: messageTextView.text) { (result) in
            guard let (_, convo) = result else {
                self.enableButtons()
                return
            }
            self.delegate?.prepareToShowNewConvo(convo)
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
}

extension MakeNewMessageViewController {
    @objc func cancelMakingNewMessage() {
        disableButtons()
        DBProxy.cancelCreatingProxy()
        if let sender = sender, senderIsNewProxy {
            DBProxy.deleteProxy(sender) { _ in
                _ = self.navigationController?.popViewController(animated: true)
            }
        } else {
            _ = navigationController?.popViewController(animated: true)
        }
    }

    func disableButtons() {
        makeNewProxyButton.isEnabled = false
        pickReceiverButton.isEnabled = false
        pickSenderButton.isEnabled = false
        sendMessageButton.isEnabled = false
    }
    
    func enableButtons() {
        makeNewProxyButton.isEnabled = true
        pickReceiverButton.isEnabled = true
        pickSenderButton.isEnabled = true
        enableSendButton()
    }
    
    func enableSendButton() {
        sendMessageButton.isEnabled = sender != nil && receiver != nil && messageTextView.text != ""
    }

    func makeNewProxy() {
        DBProxy.makeProxy { (result) in
            switch result {
            case .failure(let error):
                self.showAlert("Error Making New Proxy", message: error.description)
                self.enableButtons()
            case .success(let newProxy):
                self.senderIsNewProxy = true
                self.sender = newProxy
            }
        }
    }
}

extension MakeNewMessageViewController {
    @objc func keyboardWillShow(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }
        UIView.animate(withDuration: 0.1) {
            self.bottomConstraint.constant = keyboardFrame.size.height + 5
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        enableSendButton()
    }
}

extension MakeNewMessageViewController: ReceiverPickerDelegate {
    func setReceiver(to proxy: Proxy) {
        receiver = proxy
    }
}

extension MakeNewMessageViewController: SenderPickerDelegate {
    func setSender(to proxy: Proxy) {
        if let sender = sender, senderIsNewProxy {
            DBProxy.deleteProxy(sender) { _ in }
            senderIsNewProxy = false
            self.sender = proxy
        } else {
            sender = proxy
        }
    }
}

protocol MakeNewMessageViewControllerDelegate {
    func prepareToShowNewConvo(_ convo: Convo)
}
