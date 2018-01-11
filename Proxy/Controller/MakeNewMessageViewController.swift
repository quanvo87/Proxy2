import SearchTextField
import UIKit

class MakeNewMessageViewController: UIViewController, SenderPickerDelegate {
    @IBOutlet weak var pickSenderButton: UIButton!
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

    // todo: put this content in a tableview
    // todo: add icons next to sender and receiver
    override func viewDidLoad() {
        super.viewDidLoad()

        receiverNameTextField.becomeFirstResponder()
        receiverNameTextField.clearButtonMode = .whileEditing
        receiverNameTextField.comparisonOptions = [.caseInsensitive]
        receiverNameTextField.highlightAttributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14)]
        receiverNameTextField.maxResultsListHeight = Int(view.frame.height / 2)
        receiverNameTextField.placeholder = "Start typing to see suggestions..."
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

        manager?.load(animator: self, controller: nil, tableView: nil)

        navigationItem.rightBarButtonItems = [UIBarButtonItem.make(target: self,
                                                                   action: #selector(close),
                                                                   imageName: ButtonName.cancel),
                                              UIBarButtonItem.make(target: self,
                                                                   action: #selector(makeNewProxy),
                                                                   imageName: ButtonName.makeNewProxy)]
        navigationItem.title = "New Message"

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillShow),
                                               name: NSNotification.Name.UIKeyboardWillShow,
                                               object: view.window)

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

extension MakeNewMessageViewController: ButtonAnimating {
    func animateButton() {
        guard let item = navigationItem.rightBarButtonItems?[safe: 1] else {
            return
        }
        item.morph(loop: true)
    }

    func stopAnimatingButton() {
        guard let item = navigationItem.rightBarButtonItems?[safe: 1] else {
            return
        }
        item.stopAnimating()
    }
}

extension MakeNewMessageViewController: StoryboardMakable {
    static var identifier: String {
        return Identifier.makeNewMessageViewController
    }
}

private extension MakeNewMessageViewController {
    @IBAction func sendMessage() {
        disableButtons()
        guard let sender = sender else {
            showAlert(title: "Sender Missing", message: "Please pick one of your Proxies to send the message from.")
            enableButtons()
            return
        }
        guard
            let receiverName = receiverNameTextField.text,
            receiverName != "" else {
                showAlert(title: "Receiver Missing", message: "Please enter the receiver's name.")
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
                        self?.showAlert(title: "Receiver Has Been Deleted", message: error.localizedDescription)
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
        guard let manager = manager else {
            return
        }
        navigationController?.pushViewController(SenderPickerViewController(uid: uid, manager: manager, senderPickerDelegate: self), animated: true)
    }

    @objc func close() {
        disableButtons()
        dismiss(animated: true)
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let keyboardFrame = (info[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                return
        }
        UIView.animate(withDuration: 0.1) { [weak self] in
            self?.bottomConstraint.constant = keyboardFrame.size.height + 5
        }
    }

    @objc func makeNewProxy() {
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

    func disableButtons() {
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = false }
        pickSenderButton?.isEnabled = false
        sendMessageButton?.isEnabled = false
    }

    func enableButtons() {
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = true }
        pickSenderButton?.isEnabled = true
        sendMessageButton.isEnabled = true
    }

    func setSenderButtonTitle() {
        pickSenderButton?.setTitle(sender?.name ?? "Pick Your Sender", for: .normal)
    }
}
