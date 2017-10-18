import JSQMessagesViewController

class ConvoIconsManager: ConvoIconsManaging {
    private let receiverIconObserver = ReceiverIconObserver()
    private let senderIconObserver = SenderIconObserver()
    private var receiverId = String()
    private var senderId = String()
    private weak var collectionView: UICollectionView?

    var icons = [String : JSQMessagesAvatarImage]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }

    var receiverIcon = String() {
        didSet {
            UIImage.makeImage(named: receiverIcon) { (image) in
                guard let image = image else { return }
                self.icons[self.receiverId] = JSQMessagesAvatarImage(placeholder: image)
            }
        }
    }

    var senderIcon = String() {
        didSet {
            UIImage.makeImage(named: senderIcon) { (image) in
                guard let image = image else { return }
                self.icons[self.senderId] = JSQMessagesAvatarImage(placeholder: image)
            }
        }
    }

    func load(receiverId: String,
              receiverProxyKey: String,
              senderId: String,
              senderProxyKey: String,
              collectionView: UICollectionView) {
        self.receiverId = receiverId
        self.senderId = senderId
        self.collectionView = collectionView
        receiverIconObserver.observe(receiverOwnerId: receiverId, receiverProxyKey: receiverProxyKey, manager: self)
        senderIconObserver.observe(senderOwnerId: senderId, senderProxyKey: senderProxyKey, manager: self)
    }
}
