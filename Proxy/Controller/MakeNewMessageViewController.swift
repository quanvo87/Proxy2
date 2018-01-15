import MessageKit
import SearchTextField

class MakeNewMessageViewController: UIViewController, SenderPickerDelegate {
    override var inputAccessoryView: UIView? {
        return inputBar
    }

    var sender: Proxy? {
        didSet {
            tableView.reloadData()
        }
    }

    private let inputBar = MessageInputBar()
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private weak var makeNewMessageDelegate: MakeNewMessageDelegate?
    private weak var proxiesManager: ProxiesManaging?
    private weak var receiverNameTextField: SearchTextField?
    private lazy var inputBarDelegate = MakeNewMessageInputBarDelegate(controller: self,
                                                                       makeNewMessageDelegate: makeNewMessageDelegate,
                                                                       manager: self,
                                                                       senderPickerDelegate: self,
                                                                       textField: receiverNameTextField)
//    private lazy var loader = ProxyNamesLoader(uid)
    private lazy var tableViewDataSource = MakeNewMessageTableViewDataSource(controller: self,
                                                                             delegate: self,
                                                                             manager: proxiesManager)
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

//        receiverNameTextField.becomeFirstResponder()
//        receiverNameTextField.clearButtonMode = .whileEditing
//        receiverNameTextField.comparisonOptions = [.caseInsensitive]
//        receiverNameTextField.highlightAttributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: 14)]
//        receiverNameTextField.maxResultsListHeight = Int(view.frame.height / 2)
//        receiverNameTextField.placeholder = "Start typing to see suggestions..."
//        receiverNameTextField.theme.cellHeight = 50
//        receiverNameTextField.theme.font = .systemFont(ofSize: 14)
//        receiverNameTextField.theme.separatorColor = UIColor.lightGray.withAlphaComponent(0.5)
//        receiverNameTextField.userStoppedTypingHandler = { [weak self] in
//            guard
//                let query = self?.receiverNameTextField.text,
//                query.count > 0 else {
//                    return
//            }
//            self?.receiverNameTextField.showLoadingIndicator()
//            self?.loader.load(query) { [weak self] (items) in
//                self?.receiverNameTextField.filterItems(items)
//                self?.receiverNameTextField.stopLoadingIndicator()
//            }
//        }

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
        tableView.register(UINib(nibName: Identifier.makeNewMessageSenderTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.makeNewMessageSenderTableViewCell)
//        tableView.register(UINib(nibName: Identifier.convoDetailSenderProxyTableViewCell, bundle: nil), forCellReuseIdentifier: Identifier.convoDetailSenderProxyTableViewCell)
        tableView.sectionHeaderHeight = 0

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if proxiesManager?.proxies.count == 0 {
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

extension MakeNewMessageViewController {
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
}
