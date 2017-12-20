import MessageKit

class ConvoViewController: MessageKit.MessagesViewController {
    
    private let convo: Convo

    private var senderProxyName = ""

    private let messagesManager = MessagesManager()

    private let dataSource = ConvoCollectionViewDataSource()

    init(_ convo: Convo) {
        self.convo = convo

        super.init(nibName: nil, bundle: nil)

        messagesManager.load(convoKey: convo.key, collectionView: messagesCollectionView)

        dataSource.load(sender: Sender(id: convo.senderId, displayName: convo.senderProxyName), manager: messagesManager)

        messagesCollectionView.messagesDataSource = dataSource

        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        tabBarController?.tabBar.isHidden = false
    }
}

extension ConvoViewController: MessagesLayoutDelegate {
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 200
    }
}

extension ConvoViewController: MessagesDisplayDelegate {}
