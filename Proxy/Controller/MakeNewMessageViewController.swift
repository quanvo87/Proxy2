import UIKit

class MakeNewMessageViewController: UIViewController, UITextViewDelegate, SenderPickerDelegate {
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var makeNewProxyButton: UIButton!
    @IBOutlet weak var pickReceiverButton: UIButton!
    @IBOutlet weak var pickSenderButton: UIButton!
    @IBOutlet weak var sendMessageButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!

    var receiver: Proxy? {
        didSet {
            setReceiverButtonTitle()
        }
    }

    var sender: Proxy? {
        didSet {
            setSenderButtonTitle()
        }
    }

    private var uid = ""
    private var container: DependencyContaining = DependencyContainer.container
    private weak var delegate: MakeNewMessageDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "New Message"
        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self, action: #selector(close), imageName: ButtonName.cancel)

        messageTextView.becomeFirstResponder()
        messageTextView.delegate = self

        setSenderButtonTitle()

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: view.window)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    static func make(uid: String, delegate: MakeNewMessageDelegate, sender: Proxy?, container: DependencyContaining) -> MakeNewMessageViewController? {
        guard let controller = MakeNewMessageViewController.make() else {
            return nil
        }
        controller.uid = uid
        controller.delegate = delegate
        controller.sender = sender
        controller.container = container
        return controller
    }
}

extension MakeNewMessageViewController: StoryboardMakable {
    static var identifier: String {
        return Identifier.makeNewMessageViewController
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

private extension MakeNewMessageViewController {
    @IBAction func makeNewProxy() {
        disableButtons()
        DB.makeProxy(uid: uid, currentProxyCount: container.proxiesManager.proxies.count) { (result) in
            switch result {
            case .failure(let error):
                self.showAlert(title: "Error Making New Proxy", message: error.description)
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
        DB.sendMessage(sender: sender, receiver: receiver, text: messageTextView.text) { (result) in
            self.enableButtons()
            switch result {
            case .failure(let error):
                switch error {
                case .inputTooLong:
                    self.showAlert(title: "Message Too Long", message: error.localizedDescription)
                case .receiverDeletedProxy:
                    self.showAlert(title: "Receiver Deleted Proxy", message: error.localizedDescription)
                default:
                    self.showAlert(title: "Error Sending Message", message: error.localizedDescription)
                }
            case .success(let tuple):
                self.delegate?.newConvo = tuple.convo
                self.navigationController?.dismiss(animated: true)
            }
        }
    }

    @IBAction func showReceiverPickerController() {
        let receiverPicker = ReceiverPicker(uid: uid, controller: self)
        receiverPicker.load()
    }

    @IBAction func showSenderPickerController() {
        navigationController?.pushViewController(SenderPickerViewController(uid: uid, senderPickerDelegate: self, container: container), animated: true)
    }
}

private extension MakeNewMessageViewController {
    @objc func close() {
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
