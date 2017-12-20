import MessageKit

class ConvoDataSource {
    private var sender = Sender(id: "", displayName: "")
    private weak var manager: MessagesManaging?

    func load(sender: Sender, manager: MessagesManaging) {
        self.sender = sender
        self.manager = manager
    }
}

extension ConvoDataSource: MessagesDataSource {
    func currentSender() -> Sender {
        return sender
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return manager?.messages[indexPath.section] ?? Message()
    }

    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return manager?.messages.count ?? 0
    }
}
