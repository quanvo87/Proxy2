import MessageKit

class ConvoViewController: MessagesViewController {
    private let applicationStateObserver: ApplicationStateObserving
    private let convoObserver: ConvoObserving
    private let database: Database
    private let messagesObserver: MessagesObserving
    private let querySize: UInt
    private let soundsPlayer: SoundsPlaying
    private let unreadMessagesObserver: UnreadMessagesObserving
    private var convo: Convo? { didSet { didSetConvo() } }
    private var icons = [String: UIImage]()
    private var isPresent = false
    private var messages = [Message]()
    private var messagesToRead = Set<Message>()
    private var shouldPlaySounds = false

    init(applicationStateObserver: ApplicationStateObserving = ApplicationStateObserver(),
         convoObserver: ConvoObserving = ConvoObserver(),
         database: Database = Shared.database,
         messagesObserver: MessagesObserving = MessagesObserver(),
         querySize: UInt = DatabaseOption.querySize,
         soundsPlayer: SoundsPlaying = SoundsPlayer(),
         unreadMessagesObserver: UnreadMessagesObserving = UnreadMessagesObserver(),
         convo: Convo) {
        self.applicationStateObserver = applicationStateObserver
        self.convoObserver = convoObserver
        self.database = database
        self.messagesObserver = messagesObserver
        self.querySize = querySize
        self.soundsPlayer = soundsPlayer
        self.unreadMessagesObserver = unreadMessagesObserver
        self.convo = convo

        super.init(nibName: nil, bundle: nil)

        applicationStateObserver.applicationDidBecomeActive { [weak self] in
            self?.messagesCollectionView.reloadDataAndKeepOffset()
        }

        applicationStateObserver.applicationDidEnterBackground { [weak self] in
            self?.shouldPlaySounds = false
        }

        convoObserver.observe(convoSenderId: convo.senderId, convoKey: convo.key) { [weak self] convo in
            self?.convo = convo
        }

        maintainPositionOnKeyboardFrameChanged = true

        let activityIndicatorView = UIActivityIndicatorView(view)
        activityIndicatorView.startAnimatingAndBringToFront()
        messagesObserver.observe(convoKey: convo.key) { [weak self] messages in
            activityIndicatorView.removeFromSuperview()
            self?.messages = messages
            self?.messagesCollectionView.reloadData()
            self?.messagesCollectionView.scrollToBottom()
            guard let newMessage = messages.last else {
                return
            }
            if let shouldPlaySounds = self?.shouldPlaySounds, shouldPlaySounds,
                newMessage.sender.id != self?.convo?.senderId,
                !newMessage.hasBeenRead {
                self?.soundsPlayer.playMessageIn()
            }
            if newMessage.hasBeenRead {
                self?.shouldPlaySounds = true
            }
        }

        messageInputBar.delegate = self
        messageInputBar.inputTextView.autocorrectionType = .default
        messageInputBar.inputTextView.placeholder = "Aa"

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            target: self,
            action: #selector(showConvoDetailViewController),
            image: Image.info
        )

        unreadMessagesObserver.observe(uid: convo.senderId) { [weak self] update in
            guard let strongSelf = self else {
                return
            }
            switch update {
            case .added(let message):
                if message.parentConvoKey == strongSelf.convo?.key {
                    if strongSelf.isPresent {
                        strongSelf.database.read(message, at: Date()) { _ in }
                    } else {
                        strongSelf.messagesToRead.update(with: message)
                    }
                }
            case .removed(let message):
                if message.parentConvoKey == strongSelf.convo?.key {
                    strongSelf.messagesToRead.remove(message)
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let convo = convo else {
            _ = navigationController?.popViewController(animated: false)
            return
        }
        isPresent = true
        messagesToRead.forEach { [weak self] message in
            self?.database.read(message, at: Date()) { _ in }
        }
        NotificationCenter.default.post(name: .willEnterConvo, object: nil, userInfo: ["convoKey": convo.key])
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isPresent = false
        NotificationCenter.default.post(name: .willLeaveConvo, object: nil)
        shouldPlaySounds = false
        tabBarController?.tabBar.isHidden = false
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        guard messages.count >= querySize, indexPath.section == 0 else {
            return
        }
        let activityIndicatorView = UIActivityIndicatorView(view)
        activityIndicatorView.startAnimatingAndBringToFront()
        let message = messages[indexPath.section]
        messagesObserver.loadMessages(endingAtMessageId: message.messageId) { [weak self] olderMessages in
            activityIndicatorView.removeFromSuperview()
            if !olderMessages.isEmpty, let messages = self?.messages {
                self?.messages = olderMessages + messages
                self?.messagesCollectionView.reloadDataAndKeepOffset()
            }
        }
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
        if convo.receiverNickname != "" {
            navigationItem.title = "\"\(convo.receiverNickname)\""
        } else {
            navigationItem.title = convo.receiverProxyName
        }
        if convo.receiverIsBlocked {
            navigationItem.title?.append(" 🚫")
        }
        icons[convo.receiverProxyKey] = Image.make(convo.receiverIcon)
        icons[convo.senderProxyKey] = Image.make(convo.senderIcon)
        messagesCollectionView.reloadDataAndKeepOffset()
    }
}

// MARK: - MessageInputBarDelegate
extension ConvoViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        inputBar.inputTextView.text = ""
        guard text.count > 0, let convo = convo else {
            return
        }
        database.sendMessage(convo: convo, text: text) { _ in }
    }
}

// MARK: - MessagesDataSource
extension ConvoViewController: MessagesDataSource {
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section == 0 {
            return makeDisplayName(message)
        }
        let previousMessage = messages[indexPath.section - 1]
        if previousMessage.sender != message.sender {
            return makeDisplayName(message)
        }
        return nil
    }

    func configureAvatarView(_ avatarView: AvatarView,
                             for message: MessageType,
                             at indexPath: IndexPath,
                             in messagesCollectionView: MessagesCollectionView) {
        avatarView.backgroundColor = .clear
        avatarView.image = nil
        if indexPath.section == messages.count - 1 {
            avatarView.set(avatar: makeAvatar(message))
        } else {
            let nextMessage = messages[indexPath.section + 1]
            if nextMessage.sender != message.sender {
                avatarView.set(avatar: makeAvatar(message))
            }
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
            return Avatar(
                image: icons[convo.senderProxyKey],
                initials: convo.senderDisplayName.getFirstNChars(2).capitalized
            )
        } else {
            return Avatar(
                image: icons[convo.receiverProxyKey],
                initials: convo.receiverDisplayName.getFirstNChars(2).capitalized
            )
        }
    }

    private func makeDisplayName(_ message: MessageType) -> NSAttributedString {
        guard let convo = convo else {
            return NSAttributedString()
        }
        return NSAttributedString(
            string: isFromCurrentSender(message: message) ? convo.senderDisplayName : convo.receiverDisplayName,
            attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption1)]
        )
    }
}

// MARK: - MessagesDisplayDelegate
extension ConvoViewController: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType,
                         at indexPath: IndexPath,
                         in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if isFromCurrentSender(message: message) {
            return Color.iOSBlue
        } else {
            return Color.chatBubbleGray
        }
    }

    func detectorAttributes(for detector: DetectorType,
                            and message: MessageType,
                            at indexPath: IndexPath) -> [NSAttributedStringKey: Any] {
        return MessageLabel.defaultAttributes
    }

    func enabledDetectors(for message: MessageType,
                          at indexPath: IndexPath,
                          in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.address, .date, .phoneNumber, .url]
    }

    func messageStyle(for message: MessageType,
                      at indexPath: IndexPath,
                      in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        if indexPath.section == messages.count - 1 {
            if isFromCurrentSender(message: message) {
                return .bubbleTail(.bottomRight, .curved)
            } else {
                return .bubbleTail(.bottomLeft, .curved)
            }
        }
        let nextMessage = messages[indexPath.section + 1]
        if nextMessage.sender != message.sender {
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
    func heightForLocation(message: MessageType,
                           at indexPath: IndexPath,
                           with maxWidth: CGFloat,
                           in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 200
    }
}
