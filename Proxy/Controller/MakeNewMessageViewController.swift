import MessageKit

// todo: put keyboard movements on main queue
class MakeNewMessageViewController: UIViewController, ProxiesManaging {
    var proxies = [Proxy]() {
        didSet {
            // todo: animate make new proxy button
        }
    }
    override var inputAccessoryView: UIView? {
        return inputBar
    }
    private let database: DatabaseType
    private let inputBar = MessageInputBar()
    private let maxProxyCount: Int
    private let proxiesObserver: ProxiesObserving
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private var firstResponder: FirstResponder = .receiverTextField
    private weak var newConvoManager: NewConvoManaging?
    private lazy var inputBarDelegate = MakeNewMessageInputBarDelegate(buttonManager: self,
                                                                       controller: self,
                                                                       newConvoManager: newConvoManager,
                                                                       senderManager: senderManager,
                                                                       tableView: tableView)
    private lazy var receiverIconImageManager = ReceiverIconImageManager(setter: self,
                                                                         tableView: tableView)
    private lazy var senderManager = SenderManager(setter: self, tableView: tableView)
    private lazy var tableViewDataSource = MakeNewMessageTableViewDataSource(uid: uid,
                                                                             controller: self,
                                                                             inputBar: inputBar,
                                                                             proxiesManager: self,
                                                                             receiverIconImageManager: receiverIconImageManager,
                                                                             receiverTextFieldDelegate: self,
                                                                             senderManager: senderManager)
    private lazy var tableViewDelegate = MakeNewMessageTableViewDelegate(uid: uid,
                                                                         controller: self,
                                                                         proxiesManager: self,
                                                                         senderManager: senderManager)

    // todo: use the sender that's passed in
    init(sender: Proxy?,
         database: DatabaseType = FirebaseDatabase(),
         maxProxyCount: Int = Setting.maxProxyCount,
         proxiesObserver: ProxiesObserving = ProxiesObserver(),
         uid: String,
         newConvoManager: NewConvoManaging?) {
        self.database = database
        self.maxProxyCount = maxProxyCount
        self.proxiesObserver = proxiesObserver
        self.uid = uid
        self.newConvoManager = newConvoManager

        super.init(nibName: nil, bundle: nil)

        inputBar.delegate = inputBarDelegate
        inputBar.inputTextView.delegate = self

        navigationItem.rightBarButtonItems = [UIBarButtonItem.make(target: self,
                                                                   action: #selector(close),
                                                                   imageName: ButtonName.cancel),
                                              UIBarButtonItem.make(target: self,
                                                                   action: #selector(makeNewProxy),
                                                                   imageName: ButtonName.makeNewProxy)]
        navigationItem.title = "New Message"

        proxiesObserver.load(manager: self, uid: uid)

        tableView.dataSource = tableViewDataSource
        tableView.delegate = tableViewDelegate
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.makeNewMessageReceiverTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.makeNewMessageReceiverTableViewCell)
        tableView.register(UINib(nibName: Identifier.makeNewMessageSenderTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.makeNewMessageSenderTableViewCell)
        tableView.rowHeight = 44
        tableView.sectionHeaderHeight = 0
        tableView.reloadData()

        senderManager.sender = sender

        setFirstResponder()

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if proxies.isEmpty {
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
        item.animate(loop: true)
    }

    func stopAnimatingButton() {
        guard let item = navigationItem.rightBarButtonItems?[safe: 1] else {
            return
        }
        item.stopAnimating()
    }

    func setButtons(_ isEnabled: Bool) {
        inputBar.sendButton.isEnabled = isEnabled
        navigationItem.rightBarButtonItems?.forEach { $0.isEnabled = isEnabled }
    }
}

extension MakeNewMessageViewController: FirstResponderSetting {
    func setFirstResponder() {
        switch firstResponder {
        case .receiverTextField:
            guard let cell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? MakeNewMessageReceiverTableViewCell else {
                return
            }
            cell.receiverTextField.becomeFirstResponder()
        case .newMessageTextView:
            inputBar.inputTextView.becomeFirstResponder()
        }
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
        // todo: extract item
        guard let item = navigationItem.rightBarButtonItems?[safe: 1] else {
            return
        }
        item.animate()
        guard proxies.count < maxProxyCount else {
            showErrorAlert(ProxyError.tooManyProxies)
            return
        }
        setButtons(false)
        database.makeProxy(ownerId: uid) { [weak self] (result) in
            switch result {
            case .failure(let error):
                self?.showErrorAlert(error)
            case .success(let newProxy):
                self?.senderManager.sender = newProxy
            }
            self?.setButtons(true)
        }
    }
}
