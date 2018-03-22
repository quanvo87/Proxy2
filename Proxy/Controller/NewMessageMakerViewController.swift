import MessageKit

private enum FirstResponder {
    case receiverTextField
    case newMessageTextView
}

class NewMessageMakerViewController: UIViewController, SenderPickerDelegate {
    var sender: Proxy? { didSet { didSetSender() } }
    override var inputAccessoryView: UIView? { return messageInputBar }
    private let buttonAnimator: ButtonAnimating
    private let database: Database
    private let messageInputBar = MessageInputBar()
    private let proxiesObserver: ProxiesObserving
    private let proxyNamesLoader: ProxyNamesLoading
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private let uid: String
    private var firstResponder = FirstResponder.receiverTextField
    private var isSending = false
    private var keyboardWillHideObserver: NSObjectProtocol?
    private var lockKeyboard = true
    private var proxies = [Proxy]()
    private weak var newMessageMakerDelegate: NewMessageMakerDelegate?
    private lazy var cancelButton = UIBarButtonItem(
        target: self,
        action: #selector(close),
        image: Image.cancel
    )
    private lazy var makeNewProxyButton = UIBarButtonItem(
        target: self,
        action: #selector(makeNewProxy),
        image: Image.makeNewProxy
    )

    init(sender: Proxy?,
         buttonAnimator: ButtonAnimating = ButtonAnimator(),
         database: Database = Constant.database,
         proxiesObserver: ProxiesObserving = ProxiesObserver(),
         proxyNamesLoader: ProxyNamesLoading = ProxyNamesLoader(),
         uid: String,
         newMessageMakerDelegate: NewMessageMakerDelegate) {
        self.sender = sender
        self.buttonAnimator = buttonAnimator
        self.database = database
        self.proxiesObserver = proxiesObserver
        self.proxyNamesLoader = proxyNamesLoader
        self.uid = uid
        self.newMessageMakerDelegate = newMessageMakerDelegate

        super.init(nibName: nil, bundle: nil)

        buttonAnimator.add(makeNewProxyButton)

        keyboardWillHideObserver = NotificationCenter.default.addObserver(
            forName: .UIKeyboardWillHide,
            object: nil,
            queue: .main ) { [weak self] _ in
                if let lockKeyboard = self?.lockKeyboard, lockKeyboard {
                    self?.setFirstResponder()
                }
        }

        makeNewProxyButton.isEnabled = false

        messageInputBar.delegate = self
        messageInputBar.inputTextView.autocorrectionType = .default
        messageInputBar.inputTextView.delegate = self
        messageInputBar.inputTextView.placeholder = "Aa"

        navigationItem.rightBarButtonItems = [cancelButton, makeNewProxyButton]
        navigationItem.title = "New Message"

        proxiesObserver.observe(proxiesOwnerId: uid) { [weak self] proxies in
            if proxies.isEmpty {
                self?.buttonAnimator.animate()
            } else {
                self?.buttonAnimator.stopAnimating()
            }
            self?.makeNewProxyButton.isEnabled = true
            self?.proxies = proxies
            self?.tableView.reloadData()
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        tableView.register(
            UINib(nibName: String(describing: NewMessageMakerReceiverTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: NewMessageMakerReceiverTableViewCell.self)
        )
        tableView.register(
            UINib(nibName: String(describing: NewMessageMakerSenderTableViewCell.self), bundle: nil),
            forCellReuseIdentifier: String(describing: NewMessageMakerSenderTableViewCell.self)
        )
        tableView.rowHeight = 44
        tableView.sectionHeaderHeight = 0
        tableView.reloadData()

        view.addSubview(tableView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if proxies.isEmpty {
            buttonAnimator.animate()
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
        if let keyboardWillHideObserver = keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(keyboardWillHideObserver)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension NewMessageMakerViewController {
    var receiverCell: NewMessageMakerReceiverTableViewCell? {
        if let receiverCell = tableView.cellForRow(
            at: IndexPath(row: 1, section: 0)
            ) as? NewMessageMakerReceiverTableViewCell {
            return receiverCell
        } else {
            return nil
        }
    }

    @objc func close() {
        setButtons(false)
        dismiss(animated: true)
    }

    @objc func makeNewProxy() {
        makeNewProxyButton.animate()
        setButtons(false)
        database.makeProxy(currentProxyCount: proxies.count, ownerId: uid) { [weak self] result in
            switch result {
            case .failure(let error):
                StatusBar.showErrorStatusBarBanner(error)
            case .success(let newProxy):
                self?.sender = newProxy
            }
            self?.setButtons(true)
        }
    }

    func didSetSender() {
        tableView.reloadData()
        setFirstResponder()
    }

    func disableSendButton() {
        messageInputBar.sendButton.isEnabled = false
    }

    func setButtons(_ isEnabled: Bool) {
        makeNewProxyButton.isEnabled = isEnabled
        setSendButton()
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

    func setSendButton() {
        messageInputBar.sendButton.isEnabled =
            !isSending &&
            sender != nil &&
            receiverCell?.receiverTextField.text?.withoutWhiteSpacesAndNewLines.count ?? 0 > 1 &&
            messageInputBar.inputTextView.text.withoutWhiteSpacesAndNewLines.count > 0
    }
}

// MARK: - MessageInputBarDelegate
extension NewMessageMakerViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        inputBar.inputTextView.text = ""
        isSending = true
        setButtons(false)
        sendMessage(text) { [weak self] result in
            switch result {
            case .failure(let error):
                StatusBar.showErrorStatusBarBanner(error)
                self?.messageInputBar.inputTextView.text = text
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
        guard let receiverName = receiverCell?.receiverTextField.text, receiverName != "" else {
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
       setSendButton()
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
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: NewMessageMakerSenderTableViewCell.self)
                ) as? NewMessageMakerSenderTableViewCell else {
                    return NewMessageMakerSenderTableViewCell()
            }
            cell.load(sender)
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: String(describing: NewMessageMakerReceiverTableViewCell.self)
                ) as? NewMessageMakerReceiverTableViewCell else {
                    return NewMessageMakerReceiverTableViewCell()
            }
            cell.receiverTextField.itemSelectionHandler = { [weak self] items, index in
                let item = items[index]
                cell.iconImageView.image = item.image
                cell.receiverTextField.text = item.title
                self?.messageInputBar.inputTextView.becomeFirstResponder()
                self?.setSendButton()
            }
            cell.receiverTextField.userStoppedTypingHandler = { [weak self] in
                guard let _self = self, let query = cell.receiverTextField.text, query.count > 0 else {
                    return
                }
                cell.iconImageView.image = nil
                cell.receiverTextField.showLoadingIndicator()
                self?.proxyNamesLoader.load(query: query, senderId: _self.uid) { items in
                    cell.receiverTextField.filterItems(items)
                    cell.receiverTextField.stopLoadingIndicator()
                }
            }
            let fontSize: CGFloat = DeviceInfo.isSmallDevice ? 14 : 17
            cell.receiverTextField.highlightAttributes =
                [NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: fontSize)]
            cell.receiverTextField.theme.font = .systemFont(ofSize: fontSize)
            cell.receiverTextField.comparisonOptions = [.caseInsensitive]
            cell.receiverTextField.delegate = self
            cell.receiverTextField.maxResultsListHeight =
                DeviceInfo.isSmallDevice ? Int(view.frame.height / 4) : Int(view.frame.height / 3)
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

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        disableSendButton()
        return true
    }

    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        setSendButton()
        return true
    }
}

// MARK: - UITextViewDelegate
extension NewMessageMakerViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        firstResponder = .newMessageTextView
    }
}
