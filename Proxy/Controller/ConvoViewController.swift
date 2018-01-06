import MessageKit

class ConvoViewController: MessagesViewController, Closing {
    var shouldClose = false
    private let convo: Convo
    private let convoManager = ConvoManager()
    private let dataSource = ConvoDataSource()
    private let displayDelegate = ConvoDisplayDelegate()
    private let iconManager = IconManager()
    private let inputBarDelegate = ConvoInputBarDelegate()
    private let layoutDelegate = ConvoLayoutDelegate()
    private let messagesManager = MessagesManager()
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?

    init(convo: Convo,
         presenceManager: PresenceManaging,
         proxiesManager: ProxiesManaging,
         unreadMessagesManager: UnreadMessagesManaging) {
        self.convo = convo
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        convoManager.load(uid: convo.senderId, key: convo.key, collectionView: messagesCollectionView, navigationItem: navigationItem, closer: self)

        iconManager.load(convo: convo, collectionView: messagesCollectionView)

        inputBarDelegate.load(controller: self, manager: convoManager)

        dataSource.load(convoManager: convoManager, iconManager: iconManager, messagesManager: messagesManager)

        displayDelegate.load(dataSource: dataSource, manager: messagesManager)

        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self, action: #selector(showConvoDetailView), imageName: ButtonName.info)
        navigationItem.title = convo.receiverProxyName

        maintainPositionOnKeyboardFrameChanged = true

        messageInputBar.delegate = inputBarDelegate

        messagesCollectionView.messagesDataSource = dataSource
        messagesCollectionView.messagesDisplayDelegate = displayDelegate
        messagesCollectionView.messagesLayoutDelegate = layoutDelegate

        messagesManager.load(convoKey: convo.key, collectionView: messagesCollectionView)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        if shouldClose {
            navigationController?.popViewController(animated: false)
        }
        presenceManager?.enterConvo(convo.key)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        presenceManager?.leaveConvo(convo.key)
        tabBarController?.tabBar.isHidden = false
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard
            indexPath.section == 0,
            let message = messagesManager.messages[safe: indexPath.section] else {
                return
        }
        messagesManager.loadMessages(endingAtMessageWithId: message.messageId, querySize: Setting.querySize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ConvoViewController {
    @objc private func showConvoDetailView() {
        guard
            let presenceManager = presenceManager,
            let proxiesManager = proxiesManager,
            let unreadMessagesManager = unreadMessagesManager else {
                return
        }
        navigationController?.pushViewController(ConvoDetailViewController(convo: convo, presenceManager: presenceManager, proxiesManager: proxiesManager, unreadMessagesManager: unreadMessagesManager), animated: true)
    }
}
