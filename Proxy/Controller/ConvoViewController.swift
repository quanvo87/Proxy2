import MessageKit

class ConvoViewController: MessageKit.MessagesViewController {
    
    private let convo: Convo

    private let messagesManager = MessagesManager()

    private let dataSource = ConvoDataSource()

    private let displayDelegate = ConvoDisplayDelegate()

    private let layoutDelegate = ConvoLayoutDelegate()

    private let inputBarDelegate = ConvoInputBarDelegate()

    init(_ convo: Convo) {
        self.convo = convo

        super.init(nibName: nil, bundle: nil)

        navigationItem.title = convo.receiverProxyName

        maintainPositionOnKeyboardFrameChanged = true

        messagesManager.load(convoKey: convo.key, collectionView: messagesCollectionView)

        dataSource.load(sender: Sender(id: convo.senderId, displayName: convo.senderProxyName), manager: messagesManager)

        displayDelegate.load(dataSource)

        inputBarDelegate.load(convo)

        messagesCollectionView.messagesDataSource = dataSource

        messagesCollectionView.messagesDisplayDelegate = displayDelegate

        messagesCollectionView.messagesLayoutDelegate = layoutDelegate

        messageInputBar.delegate = inputBarDelegate
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.isHidden = false
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
