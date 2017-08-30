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
            pickReceiverButton.setTitle(receiver?.name ?? "Pick A Receiver", for: .normal)
            enableButtons()
        }
    }
    var sender: Proxy? {
        didSet {
            pickSenderButton.setTitle(sender?.name ?? "Pick A Sender", for: .normal)
            enableButtons()
        }
    }
    var senderIsNewProxy = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        messageTextView.becomeFirstResponder()
        messageTextView.delegate = self

        navigationItem.rightBarButtonItem = NavigationItemManager.makeCancelButton(target: self, selector: #selector(MakeNewMessageViewController.cancelMakingNewMessage))
        navigationItem.title = "New Message"

        NotificationCenter.default.addObserver(self, selector: #selector(MakeNewMessageViewController.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: view.window)

        sendMessageButton.isEnabled = false
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension MakeNewMessageViewController {
    @IBAction func goToReceiverPickerVC() {
        if let receiverPickerVC = storyboard?.instantiateViewController(withIdentifier: Identifier.ReceiverPickerViewController) as? ReceiverPickerViewController {
            receiverPickerVC.delegate = self
            navigationController?.pushViewController(receiverPickerVC, animated: true)
        }
    }

    @IBAction func goToSenderPickerVC() {
        if let senderPickerVC = self.storyboard?.instantiateViewController(withIdentifier: Identifier.SenderPickerTableViewController) as? SenderPickerTableViewController {
            senderPickerVC.delegate = self
            navigationController?.pushViewController(senderPickerVC, animated: true)
        }
    }

    @IBAction func makeNewProxy() {
        disableButtons()
        if let sender = sender, senderIsNewProxy {
            DBProxy.deleteProxy(sender) { (success) in
                guard success else {
                    self.enableButtons()
                    return
                }
                self.senderIsNewProxy = false
                self.makeNewProxyHelper()
            }
        } else {
            makeNewProxyHelper()
        }
    }

    @IBAction func sendMessage() {
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
                self.dismiss(animated: true)
            }
        } else {
            dismiss(animated: true)
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

    func makeNewProxyHelper() {
        DBProxy.makeProxy { (result) in
            switch result {
            case .failure(let error):
                self.showAlert("Error Making New Proxy", message: error.description)
                self.enableButtons()
            case .success(let newProxy):
                self.sender = newProxy
                self.senderIsNewProxy = true
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
            self.sender = proxy
            senderIsNewProxy = false
        } else {
            sender = proxy
        }
    }
}

protocol MakeNewMessageViewControllerDelegate {
    func prepareToShowNewConvo(_ convo: Convo)
}
