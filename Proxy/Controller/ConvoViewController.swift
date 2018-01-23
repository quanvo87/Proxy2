import MessageKit

class ConvoViewController: MessagesViewController, ConvoManaging, MessagesManaging {
    var convo: Convo? {
        didSet {
            if let convo = convo {
                icons[convo.receiverProxyKey] = UIImage(named: convo.receiverIcon)
                icons[convo.senderProxyKey] = UIImage(named: convo.senderIcon)
                messagesCollectionView.reloadDataAndKeepOffset()
                navigationItem.title = convo.receiverDisplayName

            } else {
                navigationController?.popViewController(animated: false)
            }
        }
    }
    var messages = [Message]()
    private let convoObserver: ConvoObserving
    private let database: DatabaseType
    private let messagesObserver: MessagesObserving
    private var icons = [String: UIImage]()
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?

    init(convo: Convo,
         convoObserver: ConvoObserving = ConvoObserver(),
         database: DatabaseType = FirebaseDatabase(),
         messagesObserver: MessagesObserving = MessagesObserver(),
         presenceManager: PresenceManaging?,
         proxiesManager: ProxiesManaging?,
         unreadMessagesManager: UnreadMessagesManaging?) {
        self.convo = convo
        self.convoObserver = convoObserver
        self.database = database
        self.messagesObserver = messagesObserver
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        convoObserver.load(convoKey: convo.key, convoSenderId: convo.senderId, manager: self)

        icons["blank"] = UIImage.make(color: .white)

        messagesObserver.load(convoKey: convo.key,
                              querySize: Setting.querySize,
                              collectionView: messagesCollectionView,
                              manager: self)

        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self,
                                                                 action: #selector(showConvoDetailViewController),
                                                                 imageName: ButtonName.info)

        maintainPositionOnKeyboardFrameChanged = true
        messageInputBar.delegate = self
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tabBarController?.tabBar.isHidden = true
        guard let convo = convo else {
            return
        }
        presenceManager?.enterConvo(convo.key)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tabBarController?.tabBar.isHidden = false
        guard let convo = convo else {
            return
        }
        presenceManager?.leaveConvo(convo.key)
    }

    @objc private func showConvoDetailViewController() {
        guard let convo = convo else {
            return
        }
        navigationController?.pushViewController(ConvoDetailViewController(convo: convo,
                                                                           presenceManager: presenceManager,
                                                                           proxiesManager: proxiesManager,
                                                                           unreadMessagesManager: unreadMessagesManager),
                                                 animated: true)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - MessageInputBarDelegate
extension ConvoViewController: MessageInputBarDelegate {
    func messageInputBar(_ inputBar: MessageInputBar, didPressSendButtonWith text: String) {
        inputBar.inputTextView.text = ""
        guard text.count > 0, let convo = convo else {
            return
        }
        database.sendMessage(convo: convo, text: text) { [weak self] (result) in
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
    func avatar(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Avatar {
        if indexPath.section == messages.count - 1 {
            return makeAvatar(message)
        }
        if let nextMessage = messages[safe: indexPath.section + 1],
            nextMessage.sender != message.sender {
            return makeAvatar(message)
        }
        return Avatar(image: icons["blank"], initials: "")
    }

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

    func currentSender() -> Sender {
        guard let convo = convo else {
            return Sender(id: "", displayName: "")
        }
        return Sender(id: convo.senderId, displayName: convo.senderDisplayName)
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[safe: indexPath.section] ?? Message(sender: currentSender(),
                                                            messageId: "",
                                                            data: .text(""),
                                                            dateRead: Date(),
                                                            parentConvoKey: "",
                                                            receiverId: "",
                                                            receiverProxyKey: "",
                                                            senderProxyKey: "")
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
            return UIColor.blue
        } else {
            return UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        }
    }

    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey: Any] {
        return MessageLabel.defaultAttributes
    }

    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date]
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        if indexPath.section == messages.count - 1 {
            if isFromCurrentSender(message: message) {
                return .bubbleTail(.bottomRight, .curved)
            } else {
                return .bubbleTail(.bottomLeft, .curved)
            }
        }
        if let nextMessage = messages[safe: indexPath.section + 1],
            nextMessage.sender != message.sender {
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
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        guard
            indexPath.section == 0,
            let message = messages[safe: indexPath.section] else {
                return
        }
        messagesObserver.loadMessages(endingAtMessageId: message.messageId,
                                      querySize: Setting.querySize,
                                      collectionView: messagesCollectionView,
                                      manager: self)
    }
}

// MARK: - UIImage
// https://stackoverflow.com/questions/26542035/create-uiimage-with-solid-color-in-swift
private extension UIImage {
    static func make(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let cgImage = image?.cgImage {
            return UIImage(cgImage: cgImage)
        } else {
            return UIImage()
        }
    }
}
