import SearchTextField
import UIKit

class MakeNewMessageViewController: UIViewController, UITextViewDelegate, SenderPickerDelegate {
    @IBOutlet weak var pickSenderButton: UIButton!
    @IBOutlet weak var makeNewProxyButton: UIButton!
    @IBOutlet weak var enterReceiverNameTextField: SearchTextField!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendMessageButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    var sender: Proxy? {
        didSet {
            setSenderButtonTitle()
        }
    }

    private let loader = ProxyNamesLoader()
    private var receiver: Proxy?
    private var uid = ""
    private weak var delegate: MakeNewMessageDelegate?
    private weak var proxiesManager: ProxiesManaging?

    override func viewDidLoad() {
        super.viewDidLoad()

        enterReceiverNameTextField.becomeFirstResponder()
        enterReceiverNameTextField.clearButtonMode = .whileEditing
        // todo: make proxy keys cap'd
        enterReceiverNameTextField.comparisonOptions = [.caseInsensitive]
        enterReceiverNameTextField.highlightAttributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14)]
        enterReceiverNameTextField.placeholder = "Start typing to see suggestions:"
        enterReceiverNameTextField.theme.font = .systemFont(ofSize: 14)
        enterReceiverNameTextField.theme.separatorColor = UIColor.lightGray.withAlphaComponent(0.5)
        enterReceiverNameTextField.theme.cellHeight = 50

        enterReceiverNameTextField.userStoppedTypingHandler = { [weak self] in
            guard let query = self?.enterReceiverNameTextField.text else {
                return
            }
            self?.enterReceiverNameTextField.showLoadingIndicator()
            self?.loader.load(query) { (results) in
                self?.enterReceiverNameTextField.filterStrings(results)
                self?.enterReceiverNameTextField.stopLoadingIndicator()
            }
        }

        messageTextView.delegate = self

        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self, action: #selector(close), imageName: ButtonName.cancel)
        navigationItem.title = "New Message"

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: view.window)

        setSenderButtonTitle()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    static func make(sender: Proxy?,
                     uid: String,
                     delegate: MakeNewMessageDelegate,
                     proxiesManager: ProxiesManaging,
                     proxyKeysManager: ProxyKeysManaging) -> MakeNewMessageViewController? {
        guard let controller = MakeNewMessageViewController.make() else {
            return nil
        }
        controller.sender = sender
        controller.uid = uid
        controller.delegate = delegate
        controller.proxiesManager = proxiesManager
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
        guard let proxyCount = proxiesManager?.proxies.count else {
            return
        }
        disableButtons()
        DB.makeProxy(uid: uid, currentProxyCount: proxyCount) { [weak self] (result) in
            switch result {
            case .failure(let error):
                self?.showAlert(title: "Error Making New Proxy", message: error.description)
            case .success(let newProxy):
                self?.sender = newProxy
            }
            self?.enableButtons()
        }
    }

    @IBAction func sendMessage() {
        guard let sender = sender, let receiver = receiver else {
            return
        }
        disableButtons()
        DB.sendMessage(sender: sender, receiver: receiver, text: messageTextView.text) { (result) in
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
                self.enableButtons()
            case .success(let tuple):
                self.delegate?.newConvo = tuple.convo
                self.navigationController?.dismiss(animated: true)
            }
        }
    }

    @IBAction func showSenderPickerController() {
        navigationController?.pushViewController(SenderPickerViewController(uid: uid, senderPickerDelegate: self), animated: true)
    }
}

private extension MakeNewMessageViewController {
    @objc func close() {
        disableButtons()
        dismiss(animated: true)
    }

    func disableButtons() {
        makeNewProxyButton?.isEnabled = false
        pickSenderButton?.isEnabled = false
        sendMessageButton?.isEnabled = false
    }

    func enableButtons() {
        enableSendButton()
        makeNewProxyButton?.isEnabled = true
        pickSenderButton?.isEnabled = true
    }

    func enableSendButton() {
        sendMessageButton?.isEnabled = sender != nil && receiver != nil && messageTextView.text != ""
    }

    func setSenderButtonTitle() {
        pickSenderButton?.setTitle(sender?.name ?? "Pick A Sender", for: .normal)
    }
}
