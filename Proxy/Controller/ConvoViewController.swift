import MessageKit

class ConvoViewController: MessagesViewController, Closing, MessagesManaging {
    var messages: [Message] = []
    var shouldClose = false
    private let convo: Convo
    private let displayDelegate = ConvoDisplayDelegate()
    private let inputBarDelegate = ConvoInputBarDelegate()
    private let layoutDelegate = ConvoLayoutDelegate()
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private lazy var convoManager = ConvoManager(convo)
    private lazy var iconManager = IconManager(receiverId: convo.receiverId,
                                               receiverProxyKey: convo.receiverProxyKey,
                                               senderId: convo.senderId,
                                               senderProxyKey: convo.senderProxyKey,
                                               collectionView: messagesCollectionView)
    private lazy var dataSource = ConvoDataSource(convoManager: convoManager,
                                                  iconManager: iconManager,
                                                  messagesManager: self)
    private lazy var messsagesObserver = MessagesObserver(convoKey: convo.key,
                                                          manager: self)

    init(convo: Convo,
         presenceManager: PresenceManaging,
         proxiesManager: ProxiesManaging,
         unreadMessagesManager: UnreadMessagesManaging) {
        self.convo = convo
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        convoManager.listeners.add(messagesCollectionView)
        convoManager.listeners.add(self)

        inputBarDelegate.load(controller: self, manager: convoManager)

        displayDelegate.load(dataSource: dataSource, manager: self)

        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self, action: #selector(showConvoDetailView), imageName: ButtonName.info)
        navigationItem.title = convo.receiverProxyName

        maintainPositionOnKeyboardFrameChanged = true

        messageInputBar.delegate = inputBarDelegate

        messagesCollectionView.messagesDataSource = dataSource
        messagesCollectionView.messagesDisplayDelegate = displayDelegate
        messagesCollectionView.messagesLayoutDelegate = layoutDelegate

        messsagesObserver.observe()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldClose {
            navigationController?.popViewController(animated: false)
        }
        presenceManager?.enterConvo(convo.key)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenceManager?.leaveConvo(convo.key)
        tabBarController?.tabBar.isHidden = false
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard
            indexPath.section == 0,
            let message = messages[safe: indexPath.section] else {
                return
        }
        messsagesObserver.loadMessages(endingAtMessageWithId: message.messageId)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ConvoViewController {
    @objc private func showConvoDetailView() {
        // todo: make stuff like this take in an optional, they're always gonna be optional
        navigationController?.pushViewController(ConvoDetailViewController(convo: convo,
                                                                           manager: convoManager,
                                                                           presenceManager: presenceManager,
                                                                           proxiesManager: proxiesManager,
                                                                           unreadMessagesManager: unreadMessagesManager),
                                                 animated: true)
    }
}
