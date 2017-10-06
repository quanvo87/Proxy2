import JSQMessagesViewController

class ConvoIconsManager: ConvoIconsManaging {
    let receiverIconObserver = ReceiverIconObserver()
    let senderIconObserver = SenderIconObserver()
    var convo: Convo?
    weak var collectionView: UICollectionView?

    func load(collectionView: UICollectionView, convo: Convo) {
        self.collectionView = collectionView
        self.convo = convo
        receiverIconObserver.observe(convo: convo, manager: self)
        senderIconObserver.observe(convo: convo, manager: self)
    }

    var icons = [String : JSQMessagesAvatarImage]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView?.reloadData()
            }
        }
    }

    var receiverIcon = String() {
        didSet {
            guard let receiverId = convo?.receiverId else { return }
            UIImage.makeImage(named: receiverIcon) { (image) in
                guard let image = image else { return }
                self.icons[receiverId] = JSQMessagesAvatarImage(placeholder: image)
            }
        }
    }

    var senderIcon = String() {
        didSet {
            guard let senderId = convo?.senderId else { return }
            UIImage.makeImage(named: senderIcon) { (image) in
                guard let image = image else { return }
                self.icons[senderId] = JSQMessagesAvatarImage(placeholder: image)
            }
        }
    }
}
