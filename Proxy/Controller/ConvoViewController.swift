import MessageKit

class ConvoViewController: MessagesViewController {
    private let convoObserver: ConvoObserving
    private let database: Database
    private let messagesObserver: MessagesObserving
    private let unreadMessagesObserver: UnreadMessagesObserving
    private var convo: Convo? { didSet { didSetConvo() } }
    private var icons = [String: UIImage]()
    private var isPresent = false
    private var messages = [Message]()
    private var messagesToRead = [String: Message]()

    init(convo: Convo,
         convoObserver: ConvoObserving = ConvoObserver(),
         database: Database = Firebase(),
         messagesObserver: MessagesObserving = MessagesObserver(),
         unreadMessagesObserver: UnreadMessagesObserving = UnreadMessagesObserver()) {
        self.convo = convo
        self.convoObserver = convoObserver
        self.database = database
        self.messagesObserver = messagesObserver
        self.unreadMessagesObserver = unreadMessagesObserver

        super.init(nibName: nil, bundle: nil)

        convoObserver.observe(convoKey: convo.key, convoSenderId: convo.senderId) { [weak self] convo in
            self?.convo = convo
        }

        messagesObserver.observe(convoKey: convo.key) { [weak self] messages in
            self?.messages = messages
            self?.messagesCollectionView.reloadData()
            self?.messagesCollectionView.scrollToBottom()
        }

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            target: self,
            action: #selector(showConvoDetailViewController),
            image: UIImage(named: ButtonName.info)
        )

        maintainPositionOnKeyboardFrameChanged = true

        messageInputBar.delegate = self

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self

        unreadMessagesObserver.observe(uid: convo.senderId) { [weak self] update in
            guard let _self = self else {
                return
            }
            switch update {
            case .added(let message):
                if message.parentConvoKey == _self.convo?.key {
                    if _self.isPresent {
                        _self.database.read(message, at: Date()) { _ in }
                    } else {
                        _self.messagesToRead[message.messageId] = message
                    }
                }
            case .removed(let message):
                if message.parentConvoKey == _self.convo?.key {
                    _self.messagesToRead.removeValue(forKey: message.messageId)
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard convo != nil else {
            _ = navigationController?.popViewController(animated: false)
            return
        }
        messagesToRead.values.forEach { [weak self] message in
            self?.database.read(message, at: Date()) { _ in }
        }
        isPresent = true
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isPresent = false
        tabBarController?.tabBar.isHidden = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ConvoViewController {
    @objc func showConvoDetailViewController() {
        guard let convo = convo else {
            return
        }
        navigationController?.pushViewController(ConvoDetailViewController(convo: convo), animated: true)
    }

    func didSetConvo() {
        guard let convo = convo else {
            _ = navigationController?.popViewController(animated: false)
            return
        }
        icons[convo.receiverProxyKey] = UIImage(named: convo.receiverIcon)
        icons[convo.senderProxyKey] = UIImage(named: convo.senderIcon)
        messagesCollectionView.reloadDataAndKeepOffset()
        navigationItem.title = convo.receiverDisplayName
    }
}

// MARK: - MessageInputBarDelegate
extension ConvoViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        inputBar.inputTextView.text = ""
        guard text.count > 0, let convo = convo else {
            return
        }
        database.sendMessage(convo: convo, text: text) { [weak self] result in
            switch result {
            case .failure(let error):
                self?.showErrorAlert(error)
            default:
                break
            }
        }
    }
}

// MARK: - MessagesDataSource
extension ConvoViewController: MessagesDataSource {
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section == 0 {
            return makeDisplayName(message)
        }
        if let previousMessage = messages[safe: indexPath.section - 1],
            previousMessage.sender != message.sender {
            return makeDisplayName(message)
        }
        return nil
    }

    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        avatarView.backgroundColor = .clear
        avatarView.image = nil
        if indexPath.section == messages.count - 1 {
            avatarView.set(avatar: makeAvatar(message))
        } else if let nextMessage = messages[safe: indexPath.section + 1], nextMessage.sender != message.sender {
            avatarView.set(avatar: makeAvatar(message))
        }
    }

    func currentSender() -> Sender {
        guard let convo = convo else {
            return Sender(id: "", displayName: "")
        }
        return Sender(id: convo.senderId, displayName: convo.senderDisplayName)
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }

    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }

    private func makeAvatar(_ message: MessageType) -> Avatar {
        guard let convo = convo else {
            return Avatar()
        }
        if isFromCurrentSender(message: message) {
            return Avatar(image: icons[convo.senderProxyKey],
                          initials: convo.senderDisplayName.getFirstNChars(2).capitalized)
        } else {
            return Avatar(image: icons[convo.receiverProxyKey],
                          initials: convo.receiverDisplayName.getFirstNChars(2).capitalized)
        }
    }

    private func makeDisplayName(_ message: MessageType) -> NSAttributedString {
        guard let convo = convo else {
            return NSAttributedString()
        }
        return NSAttributedString(string: isFromCurrentSender(message: message) ? convo.senderDisplayName : convo.receiverDisplayName,
                                  attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
}

// MARK: - MessagesDisplayDelegate
extension ConvoViewController: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if isFromCurrentSender(message: message) {
            return Color.blue
        } else {
            return UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        }
    }

    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey: Any] {
        return MessageLabel.defaultAttributes
    }

    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.address, .date, .phoneNumber, .url]
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        if indexPath.section == messages.count - 1 {
            if isFromCurrentSender(message: message) {
                return .bubbleTail(.bottomRight, .curved)
            } else {
                return .bubbleTail(.bottomLeft, .curved)
            }
        }
        if let nextMessage = messages[safe: indexPath.section + 1], nextMessage.sender != message.sender {
            if isFromCurrentSender(message: message) {
                return .bubbleTail(.bottomRight, .curved)
            } else {
                return .bubbleTail(.bottomLeft, .curved)
            }
        }
        return .bubble
    }
}

// MARK: - MessagesLayoutDelegate
extension ConvoViewController: MessagesLayoutDelegate {
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 200
    }
}

// MARK: - UICollectionViewDelegate
extension ConvoViewController {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard
            indexPath.section == 0,
            let message = messages[safe: indexPath.section] else {
                return
        }
        messagesObserver.loadMessages(endingAtMessageId: message.messageId) { [weak self] olderMessages in
            if let messages = self?.messages {
                self?.messages = olderMessages + messages
                self?.messagesCollectionView.reloadDataAndKeepOffset()
            }
        }
    }
}

// MARK: - Util
private extension String {
    func getFirstNChars(_ n: Int) -> String {
        guard count >= n else {
            return ""
        }
        return String(self[..<index(startIndex, offsetBy: n)])
    }
}
