import MessageKit

class ConvoViewController: MessagesViewController, Closing, IconManaging, MessagesManaging {
    var icons: [String : UIImage] = [:] {
        didSet {
            messagesCollectionView.reloadDataAndKeepOffset()
        }
    }

    var messages: [Message] = []
    var shouldClose = false
    private let convo: Convo
    private let displayDelegate = ConvoDisplayDelegate()
    private let inputBarDelegate = ConvoInputBarDelegate()
    private let layoutDelegate = ConvoLayoutDelegate()
    private weak var presenceManager: PresenceManaging?
    private weak var proxiesManager: ProxiesManaging?
    private weak var unreadMessagesManager: UnreadMessagesManaging?
    private lazy var convoManager = ConvoManager(convo)
    private lazy var dataSource = ConvoDataSource(convoManager: convoManager,
                                                  iconManager: self,
                                                  messagesManager: self)
    private lazy var messsagesObserver = MessagesObserver(convoKey: convo.key,
                                                          manager: self)
    private lazy var receiverIconObserver = IconObserver(proxyKey: convo.receiverProxyKey,
                                                         uid: convo.receiverId,
                                                         manager: self)
    private lazy var senderIconObserver = IconObserver(proxyKey: convo.senderProxyKey,
                                                       uid: convo.senderId,
                                                       manager: self)

    init(convo: Convo,
         presenceManager: PresenceManaging,
         proxiesManager: ProxiesManaging,
         unreadMessagesManager: UnreadMessagesManaging) {
        self.convo = convo
        self.presenceManager = presenceManager
        self.proxiesManager = proxiesManager
        self.unreadMessagesManager = unreadMessagesManager

        super.init(nibName: nil, bundle: nil)

        convoManager.listeners.add(messagesCollectionView)
        convoManager.listeners.add(self)

        icons["blank"] = UIImage.make(color: .white)

        inputBarDelegate.load(controller: self, manager: convoManager)

        displayDelegate.load(dataSource: dataSource, manager: self)

        navigationItem.rightBarButtonItem = UIBarButtonItem.make(target: self, action: #selector(showConvoDetailView), imageName: ButtonName.info)
        navigationItem.title = convo.receiverProxyName

        maintainPositionOnKeyboardFrameChanged = true

        messageInputBar.delegate = inputBarDelegate

        messagesCollectionView.messagesDataSource = dataSource
        messagesCollectionView.messagesDisplayDelegate = displayDelegate
        messagesCollectionView.messagesLayoutDelegate = layoutDelegate

        messsagesObserver.observe()

        receiverIconObserver.observe()
        senderIconObserver.observe()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if shouldClose {
            navigationController?.popViewController(animated: false)
        }
        presenceManager?.enterConvo(convo.key)
        tabBarController?.tabBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        presenceManager?.leaveConvo(convo.key)
        tabBarController?.tabBar.isHidden = false
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard
            indexPath.section == 0,
            let message = messages[safe: indexPath.section] else {
                return
        }
        messsagesObserver.loadMessages(endingAtMessageWithId: message.messageId)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension ConvoViewController {
    @objc private func showConvoDetailView() {
        // todo: make stuff like this take in an optional, they're always gonna be optional
        navigationController?.pushViewController(ConvoDetailViewController(convo: convo,
                                                                           manager: convoManager,
                                                                           presenceManager: presenceManager,
                                                                           proxiesManager: proxiesManager,
                                                                           unreadMessagesManager: unreadMessagesManager),
                                                 animated: true)
    }
}

// https://stackoverflow.com/questions/26542035/create-uiimage-with-solid-color-in-swift
private extension UIImage {
    static func make(color: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        if let cgImage = image?.cgImage {
            return UIImage(cgImage: cgImage)
        } else {
            return UIImage()
        }
    }
}
