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
    private let container: DependencyContaining

    init(convo: Convo, container: DependencyContaining) {
        self.convo = convo
        self.container = container

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = convo.receiverProxyName
        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self, action: #selector(showConvoDetailView), imageName: ButtonName.info)

        maintainPositionOnKeyboardFrameChanged = true

        convoManager.load(convoOwnerId: convo.senderId, convoKey: convo.key, navigationItem: navigationItem, collectionView: messagesCollectionView)

        iconManager.load(convo: convo, collectionView: messagesCollectionView)

        messagesManager.load(convoKey: convo.key, collectionView: messagesCollectionView)

        dataSource.load(convoManager: convoManager, iconManager: iconManager, messagesManager: messagesManager)

        displayDelegate.load(messagesManager: messagesManager, dataSource: dataSource)

        inputBarDelegate.load(convoManager: convoManager, controller: self)

        messagesCollectionView.messagesDataSource = dataSource
        messagesCollectionView.messagesDisplayDelegate = displayDelegate
        messagesCollectionView.messagesLayoutDelegate = layoutDelegate

        messageInputBar.delegate = inputBarDelegate
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        tabBarController?.tabBar.isHidden = true
        container.presenceManager.enterConvo(convo.key)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.isHidden = false
        container.presenceManager.leaveConvo(convo.key)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.section == 0, let message = messagesManager.messages[safe: indexPath.section] else {
            return
        }
        messagesManager.observer.getMessages(endingAtMessageWithId: message.messageId)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ConvoViewController {
    @objc private func showConvoDetailView() {
        navigationController?.pushViewController(ConvoDetailViewController(convo: convo, container: container), animated: true)
    }
}
