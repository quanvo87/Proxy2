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

    init(_ convo: Convo) {
        self.convo = convo

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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        DBConvo.setPresent(present: true, uid: convo.senderId, convoKey: convo.key) { (success) in
            if success {
                for message in self.messagesManager.messages {
                    DBMessage.read(message) { (_) in }
                }
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        DBConvo.setPresent(present: false, uid: convo.senderId, convoKey: convo.key) { (_) in }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.isHidden = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ConvoViewController {
    @objc private func showConvoDetailView() {
        guard let convo = convoManager.convo else {
            return
        }
        navigationController?.pushViewController(ConvoDetailViewController(convo), animated: true)
    }
}
