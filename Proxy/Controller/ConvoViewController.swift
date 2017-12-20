import MessageKit

class ConvoViewController: MessageKit.MessagesViewController {

    private let uid: String
    private let convo: Convo

    private var senderProxyName = ""

    private var messages = [MessageType]()

    init(uid: String, convo: Convo) {
        self.uid = uid
        self.convo = convo

        super.init(nibName: nil, bundle: nil)

        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ConvoViewController: MessagesDataSource {
    func currentSender() -> Sender {
        return Sender(id: uid, displayName: senderProxyName)
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }

    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
}

extension ConvoViewController: MessagesLayoutDelegate {
    func heightForLocation(message: MessageType, at indexPath: IndexPath, with maxWidth: CGFloat, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 200
    }
}

extension ConvoViewController: MessagesDisplayDelegate {}
