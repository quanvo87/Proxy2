import MessageKit

class ConvoViewController: MessagesViewController {
    private let convo: Convo
    private let convoManager = ConvoManager()
    private let iconManager = IconManager()
    private let messagesManager = MessagesManager()
    private let dataSource = ConvoDataSource()
    private let displayDelegate = ConvoDisplayDelegate()
    private let layoutDelegate = ConvoLayoutDelegate()
    private let inputBarDelegate = ConvoInputBarDelegate()
    private weak var unreadMessagesManager: UnreadMessagesManaging?

    init(convo: Convo, unreadMessagesManager: UnreadMessagesManaging?) {
        self.convo = convo
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = convo.receiverProxyName
        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self, action: #selector(showConvoDetailView), imageName: ButtonName.info)

        maintainPositionOnKeyboardFrameChanged = true

        convoManager.load(convoOwnerId: convo.senderId, convoKey: convo.key, navigationItem: navigationItem, collectionView: messagesCollectionView)

        iconManager.load(convo: convo, collectionView: messagesCollectionView)

        messagesManager.load(convoKey: convo.key, collectionView: messagesCollectionView)

        dataSource.load(convoManager: convoManager, iconManager: iconManager, messagesManager: messagesManager)

        displayDelegate.load(messagesManager: messagesManager, dataSource: dataSource)

        inputBarDelegate.load(convo: convo, controller: self)

        messagesCollectionView.messagesDataSource = dataSource
        messagesCollectionView.messagesDisplayDelegate = displayDelegate
        messagesCollectionView.messagesLayoutDelegate = layoutDelegate

        messageInputBar.delegate = inputBarDelegate
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        tabBarController?.tabBar.isHidden = true
        unreadMessagesManager?.enterConvo(convo.key)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.isHidden = false
        unreadMessagesManager?.leaveConvo(convo.key)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.section == 0 else {
            return
        }
        guard messagesManager.messages.count >= Setting.messagesPageSize else {
            return
        }
        guard let message = messagesManager.messages[safe: indexPath.section] else {
            return
        }
        guard message.messageId != convo.firstMessageId else {
            return
        }
        messagesManager.observer.getMessages(startingAtMessageWithId: message.messageId)
    }
}

private extension ConvoViewController {
    @objc private func showConvoDetailView() {
        navigationController?.pushViewController(ConvoDetailViewController(convo: convo, unreadMessagesManager: unreadMessagesManager), animated: true)
    }
}
