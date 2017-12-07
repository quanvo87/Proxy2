import JSQMessagesViewController

class ConvoIconsManager: ConvoIconsManaging {
    var convoIcons = [String : JSQMessagesAvatarImage]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }

    var receiverIcon: String = "" {
        didSet {
            UIImage.makeImage(named: receiverIcon) { (image) in
                guard let image = image else {
                    return
                }
                self.convoIcons[self.receiverId] = JSQMessagesAvatarImage(placeholder: image)
            }
        }
    }

    var senderIcon: String = "" {
        didSet {
            UIImage.makeImage(named: senderIcon) { (image) in
                guard let image = image else {
                    return
                }
                self.convoIcons[self.senderId] = JSQMessagesAvatarImage(placeholder: image)
            }
        }
    }

    private let receiverIconObserver = ReceiverIconObserver()
    private let senderIconObserver = SenderIconObserver()
    private var receiverId = ""
    private var senderId = ""
    private weak var collectionView: UICollectionView?

    func load(convo: Convo, collectionView: UICollectionView) {
        self.receiverId = convo.receiverId
        self.senderId = convo.senderId
        self.collectionView = collectionView
        receiverIconObserver.observe(receiverOwnerId: convo.receiverId, receiverProxyKey: convo.receiverProxyKey, manager: self)
        senderIconObserver.observe(senderOwnerId: convo.senderId, senderProxyKey: convo.senderProxyKey, manager: self)
    }
}
