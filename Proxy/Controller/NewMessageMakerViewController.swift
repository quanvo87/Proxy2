import Device
import MessageKit

private enum FirstResponder {
    case receiverTextField
    case newMessageTextView
}

class NewMessageMakerViewController: UIViewController, SenderPickerDelegate {
    var sender: Proxy? { didSet { didSetSender() } }
    override var inputAccessoryView: UIView? { return messageInputBar }
    private let database: Database
    private let messageInputBar = MessageInputBar()
    private let proxiesObserver: ProxiesObserving
    private let proxyNamesLoader: ProxyNamesLoading
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private var firstResponder = FirstResponder.receiverTextField
    private var isSending = false
    private var lockKeyboard = true
    private var proxies = [Proxy]()
    private lazy var cancelButton = makeCancelButton()
    private lazy var makeNewProxyButton = makeMakeNewProxyButton()
    private weak var newMessageMakerDelegate: NewMessageMakerDelegate?

    init(sender: Proxy?,
         database: Database = Firebase(),
         proxiesObserver: ProxiesObserving = ProxiesObserver(),
         proxyNamesLoader: ProxyNamesLoading = ProxyNamesLoader(),
         uid: String,
         newMessageMakerDelegate: NewMessageMakerDelegate) {
        self.sender = sender
        self.database = database
        self.proxiesObserver = proxiesObserver
        self.proxyNamesLoader = proxyNamesLoader
        self.uid = uid
        self.newMessageMakerDelegate = newMessageMakerDelegate

        super.init(nibName: nil, bundle: nil)

        makeNewProxyButton.isEnabled = false

        messageInputBar.delegate = self
        messageInputBar.inputTextView.delegate = self

        navigationItem.rightBarButtonItems = [cancelButton, makeNewProxyButton]
        navigationItem.title = "New Message"

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(keyboardWillHide),
                                               name: NSNotification.Name.UIKeyboardWillHide,
                                               object: nil)

        proxiesObserver.observe(proxiesOwnerId: uid) { [weak self] proxies in
            if proxies.isEmpty {
                self?.makeNewProxyButton.animate(loop: true)
            } else {
                self?.makeNewProxyButton.stopAnimating()
            }
            self?.makeNewProxyButton.isEnabled = true
            self?.proxies = proxies
            self?.tableView.reloadData()
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(UINib(nibName: Identifier.makeNewMessageReceiverTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.makeNewMessageReceiverTableViewCell)
        tableView.register(UINib(nibName: Identifier.makeNewMessageSenderTableViewCell, bundle: nil),
                           forCellReuseIdentifier: Identifier.makeNewMessageSenderTableViewCell)
        tableView.rowHeight = 44
        tableView.sectionHeaderHeight = 0
        tableView.reloadData()

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if proxies.isEmpty {
            makeNewProxyButton.animate(loop: true)
        }
        lockKeyboard = true
        setFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lockKeyboard = false
        DispatchQueue.main.async { [weak self] in
            self?.view.endEditing(true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension NewMessageMakerViewController {
    var receiverCell: MakeNewMessageReceiverTableViewCell? {
        if let receiverCell = tableView.cellForRow(at: IndexPath(row: 1, section: 0)) as? MakeNewMessageReceiverTableViewCell {
            return receiverCell
        } else {
            return nil
        }
    }

    @objc func close() {
        setButtons(false)
        dismiss(animated: true)
    }

    @objc func keyboardWillHide() {
        if lockKeyboard {
            setFirstResponder()
        }
    }

    @objc func makeNewProxy() {
        makeNewProxyButton.animate()
        setButtons(false)
        database.makeProxy(currentProxyCount: proxies.count, ownerId: uid) { [weak self] result in
            switch result {
            case .failure(let error):
                self?._showErrorAlert(error)
            case .success(let newProxy):
                self?.sender = newProxy
            }
            self?.setButtons(true)
        }
    }

    func _showErrorAlert(_ error: Error) {
        lockKeyboard = false
        showErrorAlert(error) { [weak self] in
            self?.lockKeyboard = true
        }
    }

    func didSetSender() {
        tableView.reloadData()
        setFirstResponder()
    }

    func makeCancelButton() -> UIBarButtonItem {
        return UIBarButtonItem.make(target: self,
                                    action: #selector(close),
                                    imageName: ButtonName.cancel)
    }

    func makeMakeNewProxyButton() -> UIBarButtonItem {
        return UIBarButtonItem.make(target: self,
                                    action: #selector(makeNewProxy),
                                    imageName: ButtonName.makeNewProxy)
    }

    func setButtons(_ isEnabled: Bool) {
        messageInputBar.sendButton.isEnabled = isEnabled
        makeNewProxyButton.isEnabled = isEnabled
    }

    func setFirstResponder() {
        switch firstResponder {
        case .receiverTextField:
            if let receiverCell = receiverCell {
                receiverCell.receiverTextField.becomeFirstResponder()
            }
        case .newMessageTextView:
            messageInputBar.inputTextView.becomeFirstResponder()
        }
    }
}

// MARK: - MessageInputBarDelegate
extension NewMessageMakerViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        inputBar.inputTextView.text = ""
        isSending = true
        setButtons(false)
        sendMessage(text) { [weak self] outcome in
            switch outcome {
            case .failure(let error):
                self?._showErrorAlert(error)
                self?.isSending = false
                self?.setButtons(true)
            case .success(let convo):
                self?.newMessageMakerDelegate?.newConvo = convo
                self?.navigationController?.dismiss(animated: false)
            }
        }
    }

    private func sendMessage(_ text: String, completion: @escaping (Result<Convo, Error>) -> Void) {
        guard text != "" else {
            completion(.failure(ProxyError.blankMessage))
            return
        }
        guard let sender = sender else {
            completion(.failure(ProxyError.senderMissing))
            return
        }
        guard
            let receiverName = receiverCell?.receiverTextField.text,
            receiverName != "" else {
                completion(.failure(ProxyError.receiverMissing))
                return
        }
        database.getProxy(proxyKey: receiverName) { [weak self] result in
            switch result {
            case .failure:
                completion(.failure(ProxyError.receiverNotFound))
            case .success(let receiver):
                self?.database.sendMessage(sender: sender, receiver: receiver, text: text) { result in
                    switch result {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success(let tuple):
                        completion(.success(tuple.convo))
                    }
                }
            }
        }
    }

    func messageInputBar(_ inputBar: MessageInputBar, textViewTextDidChangeTo text: String) {
        if isSending {
            inputBar.sendButton.isEnabled = false
        } else {
            inputBar.sendButton.isEnabled = text != ""
        }
    }
}

// MARK: - UITableViewDataSource
extension NewMessageMakerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.row {
        case 0:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.makeNewMessageSenderTableViewCell) as? MakeNewMessageSenderTableViewCell else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.makeNewMessageSenderTableViewCell, for: indexPath)
            }
            cell.load(sender)
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.makeNewMessageReceiverTableViewCell) as? MakeNewMessageReceiverTableViewCell else {
                return tableView.dequeueReusableCell(withIdentifier: Identifier.makeNewMessageReceiverTableViewCell, for: indexPath)
            }
            cell.receiverTextField.itemSelectionHandler = { [weak self] items, index in
                guard let item = items[safe: index] else {
                    return
                }
                cell.iconImageView.image = item.image
                cell.receiverTextField.text = item.title
                self?.messageInputBar.inputTextView.becomeFirstResponder()
            }
            cell.receiverTextField.userStoppedTypingHandler = { [weak self] in
                guard
                    let _self = self,
                    let query = cell.receiverTextField.text,
                    query.count > 0 else {
                        return
                }
                cell.iconImageView.image = nil
                cell.receiverTextField.showLoadingIndicator()
                self?.proxyNamesLoader.load(query: query, senderId: _self.uid) { items in
                    cell.receiverTextField.filterItems(items)
                    cell.receiverTextField.stopLoadingIndicator()
                }
            }
            let fontSize: CGFloat = isSmallDevice ? 14 : 17
            cell.receiverTextField.highlightAttributes = [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: fontSize)]
            cell.receiverTextField.theme.font = .systemFont(ofSize: fontSize)
            cell.receiverTextField.comparisonOptions = [.caseInsensitive]
            cell.receiverTextField.delegate = self
            cell.receiverTextField.maxResultsListHeight = isSmallDevice ? Int(view.frame.height / 4) : Int(view.frame.height / 3)
            cell.receiverTextField.theme.cellHeight = 50
            cell.receiverTextField.theme.separatorColor = UIColor.lightGray.withAlphaComponent(0.5)
            return cell
        default:
            return UITableViewCell()
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 && proxies.isEmpty {
            return "Tap the bouncing button to make a new Proxy 🎉."
        } else {
            return nil
        }
    }

    private var isSmallDevice: Bool {
        switch Device.size() {
        case .screen3_5Inch:
            return true
        case .screen4Inch:
            return true
        default:
            return false
        }
    }
}

// MARK: - UITableViewDelegate
extension NewMessageMakerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row == 0 else {
            return
        }
        tableView.deselectRow(at: indexPath, animated: true)
        let senderPickerViewController = SenderPickerViewController(uid: uid, senderPickerDelegate: self)
        navigationController?.pushViewController(senderPickerViewController, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return CGFloat.leastNormalMagnitude
    }
}

// MARK: - UITextFieldDelegate
extension NewMessageMakerViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        firstResponder = .receiverTextField
    }
}

// MARK: - UITextViewDelegate
extension NewMessageMakerViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        firstResponder = .newMessageTextView
    }
}