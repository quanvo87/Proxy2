import MessageKit
import SearchTextField

private enum FirstResponder {
    case receiverTextField
    case newMessageTextView
}

class MakeNewMessageViewController: UIViewController, ReceiverIconImageManaging, SenderPickerDelegate {
    var receiverIconImage: UIImage? {
        didSet {
            tableView.reloadData()
            makeReceiverTextFieldFirstResponder()
        }
    }
    var sender: Proxy? {
        didSet {
            tableView.reloadData()
            switch firstResponder {
            case .receiverTextField:
                makeReceiverTextFieldFirstResponder()
            case .newMessageTextView:
                inputBar.inputTextView.becomeFirstResponder()
            }
        }
    }
    override var inputAccessoryView: UIView? {
        return inputBar
    }
    private let inputBar = MessageInputBar()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private var firstResponder: FirstResponder = .receiverTextField
    private weak var makeNewMessageDelegate: MakeNewMessageDelegate?
    private weak var proxiesManager: ProxiesManaging?
    private lazy var inputBarDelegate = MakeNewMessageInputBarDelegate(buttonManager: self,
                                                                       controller: self,
                                                                       makeNewMessageDelegate: makeNewMessageDelegate,
                                                                       senderPickerDelegate: self,
                                                                       tableView: tableView)
    private lazy var tableViewDataSource = MakeNewMessageTableViewDataSource(uid: uid,
                                                                             controller: self,
                                                                             delegate: self,
                                                                             proxiesManager: proxiesManager,
                                                                             receiverIconImageManager: self,
                                                                             receiverTextFieldDelegate: self)
    private lazy var tableViewDelegate = MakeNewMessageTableViewDelegate(uid: uid,
                                                                         controller: self,
                                                                         delegate: self,
                                                                         manager: proxiesManager)

    init(sender: Proxy?,
         uid: String,
         delegate: MakeNewMessageDelegate?,
         manager: ProxiesManaging?) {
        self.uid = uid
        self.sender = sender
        self.makeNewMessageDelegate = delegate
        self.proxiesManager = manager

        super.init(nibName: nil, bundle: nil)

        inputBar.delegate = inputBarDelegate
        inputBar.inputTextView.delegate = self

        manager?.addManager(self)

        navigationItem.rightBarButtonItems = [UIBarButtonItem.make(target: self,
                                                                   action: #selector(close),
                                                                   imageName: ButtonName.cancel),
                                              UIBarButtonItem.make(target: self,
                                                                   action: #selector(makeNewProxy),
                                                                   imageName: ButtonName.makeNewProxy)]
        navigationItem.title = "New Message"

        tableView.dataSource = tableViewDataSource
        tableView.delegate = tableViewDelegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.makeNewMessageReceiverTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.makeNewMessageReceiverTableViewCell)
        tableView.register(UINib(nibName: Identifier.makeNewMessageSenderTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.makeNewMessageSenderTableViewCell)
        tableView.rowHeight = 44
        tableView.sectionHeaderHeight = 0

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if proxiesManager?.proxies.isEmpty ?? false {
            animateButton()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension MakeNewMessageViewController: ButtonManaging {
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

    func setButtons(_ isEnabled: Bool) {
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = isEnabled }
    }
}

extension MakeNewMessageViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        firstResponder = .receiverTextField
    }
}

extension MakeNewMessageViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        firstResponder = .newMessageTextView
    }
}

private extension MakeNewMessageViewController {
    @objc func close() {
        setButtons(false)
        dismiss(animated: true)
    }

    @objc func makeNewProxy() {
        guard let item = navigationItem.rightBarButtonItems?[safe: 1] else {
            return
        }
        item.morph()
        guard let proxyCount = proxiesManager?.proxies.count else {
            return
        }
        setButtons(false)
        DB.makeProxy(uid: uid, currentProxyCount: proxyCount) { [weak self] (result) in
            switch result {
            case .failure(let error):
                self?.showAlert(title: "Error Making New Proxy", message: error.description)
            case .success(let newProxy):
                self?.sender = newProxy
            }
            self?.setButtons(true)
        }
    }

    func makeReceiverTextFieldFirstResponder() {
        guard let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? MakeNewMessageReceiverTableViewCell else {
            return
        }
        cell.receiverTextField.becomeFirstResponder()
    }
}
