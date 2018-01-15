import MessageKit

class ConvoViewController: MessagesViewController, Closing {
    var shouldClose = false
    private let convo: Convo
    private let layoutDelegate = ConvoLayoutDelegate()
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private lazy var convoManager = ConvoManager(convo)
    private lazy var dataSource = ConvoDataSource(convoManager: convoManager,
                                                  iconManager: iconManager,
                                                  messagesManager: messagesManager)
    private lazy var displayDelegate = ConvoDisplayDelegate(dataSource: dataSource,
                                                            manager: messagesManager)
    private lazy var iconManager = IconManager(receiverId: convo.receiverId,
                                               receiverProxyKey: convo.receiverProxyKey,
                                               senderId: convo.senderId,
                                               senderProxyKey: convo.senderProxyKey,
                                               collectionView: messagesCollectionView)
    private lazy var inputBarDelegate = ConvoInputBarDelegate(controller: self,
                                                              manager: convoManager)
    private lazy var messagesManager = MessagesManager(convoKey: convo.key,
                                                       collectionView: messagesCollectionView)

    init(convo: Convo,
         presenceManager: PresenceManaging?,
         proxiesManager: ProxiesManaging?,
         unreadMessagesManager: UnreadMessagesManaging?) {
        self.convo = convo
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        convoManager.addCloser(self)
        convoManager.addCollectionView(messagesCollectionView)
        convoManager.addController(self)

        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self,
                                                                 action: #selector(showConvoDetailView),
                                                                 imageName: ButtonName.info)
        navigationItem.title = convo.receiverProxyName

        maintainPositionOnKeyboardFrameChanged = true

        messageInputBar.delegate = inputBarDelegate

        messagesCollectionView.messagesDataSource = dataSource
        messagesCollectionView.messagesDisplayDelegate = displayDelegate
        messagesCollectionView.messagesLayoutDelegate = layoutDelegate
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

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        guard
            indexPath.section == 0,
            let message = messagesManager.messages[safe: indexPath.section] else {
                return
        }
        messagesManager.loadMessages(endingAtMessageId: message.messageId)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ConvoViewController {
    @objc private func showConvoDetailView() {
        navigationController?.pushViewController(ConvoDetailViewController(convo: convo,
                                                                           convoManager: convoManager,
                                                                           presenceManager: presenceManager,
                                                                           proxiesManager: proxiesManager,
                                                                           unreadMessagesManager: unreadMessagesManager),
                                                 animated: true)
    }
}
