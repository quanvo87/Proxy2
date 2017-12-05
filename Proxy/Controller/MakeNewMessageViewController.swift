import UIKit

class MakeNewMessageViewController: UIViewController, UITextViewDelegate, SenderPickerDelegate {
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var makeNewProxyButton: UIButton!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var pickReceiverButton: UIButton!
    @IBOutlet weak var pickSenderButton: UIButton!
    @IBOutlet weak var sendMessageButton: UIButton!
    private var uid = ""
    private weak var delegate: MakeNewMessageDelegate?
    var receiver: Proxy? { didSet { setReceiverButtonTitle() } }
    var sender: Proxy? { didSet { setSenderButtonTitle() } }

    static func make(delegate: MakeNewMessageDelegate, sender: Proxy?, uid: String) -> MakeNewMessageViewController? {
        guard let controller = MakeNewMessageViewController.make() else {
            return nil
        }
        controller.delegate = delegate
        controller.sender = sender
        controller.uid = uid
        return controller
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = "New Message"
        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self, action: #selector(close), imageName: .cancel)

        messageTextView.becomeFirstResponder()
        messageTextView.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: view.window)

        setSenderButtonTitle()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension MakeNewMessageViewController: StoryboardMakable {
    static var identifier: String { return Name.makeNewMessageViewController }
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
        DBProxy.makeProxy(forUser: uid) { (result) in
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
                self.showAlert("Error Sending Message", message: "There was an error sending the message. Please try again.")
                return
            }
            self.delegate?.newConvo = convo
            _ = self.navigationController?.popViewController(animated: true)
        }
    }

    @IBAction func showReceiverPickerController() {
        let receiverPicker = ReceiverPicker(controller: self, uid: uid)
        receiverPicker.load()
    }

    @IBAction func showSenderPickerController() {
        navigationController?.pushViewController(SenderPickerViewController(senderPickerDelegate: self, uid: uid), animated: true)
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
