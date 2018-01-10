import SearchTextField
import UIKit

class MakeNewMessageViewController: UIViewController, SenderPickerDelegate {
    @IBOutlet weak var chooseSenderButton: UIButton!
    @IBOutlet weak var makeNewProxyButton: UIButton!
    @IBOutlet weak var receiverNameTextField: SearchTextField!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var sendMessageButton: UIButton!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!

    var sender: Proxy? {
        didSet {
            setSenderButtonTitle()
        }
    }

    private var uid = ""
    private weak var delegate: MakeNewMessageDelegate?
    private weak var manager: ProxiesManaging?
    private lazy var loader = ProxyNamesLoader(uid)

    override func viewDidLoad() {
        super.viewDidLoad()

        receiverNameTextField.becomeFirstResponder()
        receiverNameTextField.clearButtonMode = .whileEditing
        receiverNameTextField.comparisonOptions = [.caseInsensitive]
        receiverNameTextField.highlightAttributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14)]
        receiverNameTextField.maxResultsListHeight = Int(view.frame.height / 2)
        receiverNameTextField.placeholder = "Start typing to see suggestions:"
        receiverNameTextField.theme.cellHeight = 50
        receiverNameTextField.theme.font = .systemFont(ofSize: 14)
        receiverNameTextField.theme.separatorColor = UIColor.lightGray.withAlphaComponent(0.5)
        receiverNameTextField.userStoppedTypingHandler = { [weak self] in
            guard
                let query = self?.receiverNameTextField.text,
                query.count > 0 else {
                    return
            }
            self?.receiverNameTextField.showLoadingIndicator()
            self?.loader.load(query) { [weak self] (items) in
                self?.receiverNameTextField.filterItems(items)
                self?.receiverNameTextField.stopLoadingIndicator()
            }
        }

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
                     manager: ProxiesManaging) -> MakeNewMessageViewController? {
        guard let controller = MakeNewMessageViewController.make() else {
            return nil
        }
        controller.sender = sender
        controller.uid = uid
        controller.delegate = delegate
        controller.manager = manager
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
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.1) {
                self.bottomConstraint.constant = keyboardFrame.size.height + 5
            }
        }
    }
}

private extension MakeNewMessageViewController {
    @IBAction func makeNewProxy() {
        guard let proxyCount = manager?.proxies.count else {
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
        disableButtons()
        guard let sender = sender else {
            showAlert(title: "Choose A Sender", message: "Please choose a Proxy to send your message from.")
            enableButtons()
            return
        }
        guard
            let receiverName = receiverNameTextField.text,
            receiverName != "" else {
                showAlert(title: "Choose A Receiver", message: "Please enter the receiver's name.")
                enableButtons()
                return
        }
        DB.getProxy(key: receiverName) { [weak self] (receiver) in
            guard let receiver = receiver else {
                self?.showAlert(title: "Receiver Not Found", message: "The receiver you chose could not be found. Please try again.")
                self?.enableButtons()
                return
            }
            guard
                let text = self?.messageTextView.text,
                text != "" else {
                    self?.showAlert(title: "Blank Message", message: "Please type the message you would like to send \(String.randomEmoji).")
                    self?.enableButtons()
                    return
            }
            DB.sendMessage(sender: sender, receiver: receiver, text: text) { [weak self] (result) in
                switch result {
                case .failure(let error):
                    switch error {
                    case .inputTooLong:
                        self?.showAlert(title: "Message Too Long", message: error.localizedDescription)
                    case .receiverDeletedProxy:
                        self?.showAlert(title: "Receiver Deleted Proxy", message: error.localizedDescription)
                    default:
                        self?.showAlert(title: "Error Sending Message", message: error.localizedDescription)
                    }
                    self?.enableButtons()
                case .success(let tuple):
                    self?.delegate?.newConvo = tuple.convo
                    self?.navigationController?.dismiss(animated: true)
                }
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
        chooseSenderButton?.isEnabled = false
        sendMessageButton?.isEnabled = false
    }

    func enableButtons() {
        makeNewProxyButton?.isEnabled = true
        chooseSenderButton?.isEnabled = true
        sendMessageButton.isEnabled = true
    }

    func setSenderButtonTitle() {
        chooseSenderButton?.setTitle(sender?.name ?? "Choose Your Sender", for: .normal)
    }
}
