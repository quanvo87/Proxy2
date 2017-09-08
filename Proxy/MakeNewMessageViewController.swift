class MakeNewMessageViewController: UIViewController, UITextViewDelegate {
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var makeNewProxyButton: UIButton?
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var pickReceiverButton: UIButton?
    @IBOutlet weak var pickSenderButton: UIButton?
    @IBOutlet weak var sendMessageButton: UIButton?

    private var receiver: Proxy? {
        didSet {
            setReceiverButtonTitle()
        }
    }
    private var sender: Proxy? {
        didSet {
            setSenderButtonTitle()
        }
    }

    private weak var delegate: MakeNewMessageDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        messageTextView.becomeFirstResponder()
        messageTextView.delegate = self

        navigationItem.rightBarButtonItem = ButtonManager.makeButton(target: self, action: #selector(self.cancelMakingNewMessage), imageName: .cancel)
        navigationItem.title = "New Message"

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: view.window)

        setSenderButtonTitle()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func setDelegate(to delegate: MakeNewMessageDelegate) {
        self.delegate = delegate
    }

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

private extension MakeNewMessageViewController {
    @IBAction func goToReceiverPickerVC() {
        guard let receiverPickerVC = storyboard?.instantiateViewController(withIdentifier: Identifier.receiverPickerViewController) as? ReceiverPickerViewController else { return }
        receiverPickerVC.delegate = self
        navigationController?.pushViewController(receiverPickerVC, animated: true)
    }

    @IBAction func goToSenderPickerVC() {
        guard let senderPickerVC = self.storyboard?.instantiateViewController(withIdentifier: Identifier.senderPickerTableViewController) as? SenderPickerTableViewController else { return }
        senderPickerVC.setDelegate(to: self)
        navigationController?.pushViewController(senderPickerVC, animated: true)
    }

    @IBAction func makeNewProxy() {
        disableButtons()
        DBProxy.makeProxy { (result) in
            switch result {
            case .failure(let error):
                self.showAlert("Error Making New Proxy", message: error.description)
                self.enableButtons()
            case .success(let newProxy):
                self.sender = newProxy
            }
        }
    }

    @IBAction func sendMessage() {
        guard let sender = sender, let receiver = receiver else {
            return
        }
        disableButtons()
        DBMessage.sendMessage(from: sender, to: receiver, withText: messageTextView.text) { (result) in
            guard let (_, convo) = result else {
                self.enableButtons()
                return
            }
            self.delegate?.setNewConvo(to: convo)
            _ = self.navigationController?.popViewController(animated: true)
        }
    }
}

private extension MakeNewMessageViewController {
    @objc func cancelMakingNewMessage() {
        DBProxy.cancelCreatingProxy()
        disableButtons()
        dismiss(animated: true)
    }

    func disableButtons() {
        makeNewProxyButton?.isEnabled = false
        pickReceiverButton?.isEnabled = false
        pickSenderButton?.isEnabled = false
        sendMessageButton?.isEnabled = false
    }

    func enableButtons() {
        enableSendButton()
        makeNewProxyButton?.isEnabled = true
        pickReceiverButton?.isEnabled = true
        pickSenderButton?.isEnabled = true
    }

    func enableSendButton() {
        sendMessageButton?.isEnabled = sender != nil && receiver != nil && messageTextView.text != ""
    }

    func setReceiverButtonTitle() {
        enableButtons()
        pickReceiverButton?.setTitle(receiver?.name ?? "Pick A Receiver", for: .normal)
    }

    func setSenderButtonTitle() {
        enableButtons()
        pickSenderButton?.setTitle(sender?.name ?? "Pick A Sender", for: .normal)
    }
}

extension MakeNewMessageViewController: ReceiverPickerDelegate {
    func setReceiver(to proxy: Proxy) {
        receiver = proxy
    }
}

extension MakeNewMessageViewController: SenderPickerDelegate {
    func setSender(to proxy: Proxy) {
        sender = proxy
    }
}

protocol MakeNewMessageDelegate: class {
    func setNewConvo(to convo: Convo)
}
