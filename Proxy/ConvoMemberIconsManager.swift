import JSQMessagesViewController

class ConvoMemberIconsManager: ConvoMemberIconsManaging {
    let receiverIconObserver = ReceiverIconObserver()
    let senderIconObserver = SenderIconObserver()
    var convo: Convo?
    weak var reloader: CollectionViewReloader?

    func load(convo: Convo, reloader: CollectionViewReloader) {
        self.convo = convo
        self.reloader = reloader
        receiverIconObserver.observe(convo: convo, manager: self)
        senderIconObserver.observe(convo: convo, manager: self)
    }

    var convoMemberIcons = [String : JSQMessagesAvatarImage]() {
        didSet {
            DispatchQueue.main.async {
                self.reloader?.reload()
            }
        }
    }

    var receiverIcon = String() {
        didSet {
            guard let receiverId = convo?.receiverId else { return }
            UIImage.makeImage(named: receiverIcon) { (image) in
                guard let image = image else { return }
                self.convoMemberIcons[receiverId] = JSQMessagesAvatarImage(placeholder: image)
            }
        }
    }

    var senderIcon = String() {
        didSet {
            guard let senderId = convo?.senderId else { return }
            UIImage.makeImage(named: senderIcon) { (image) in
                guard let image = image else { return }
                self.convoMemberIcons[senderId] = JSQMessagesAvatarImage(placeholder: image)
            }
        }
    }
}
