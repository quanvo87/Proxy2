import MessageKit

class ConvoDisplayDelegate {
    private weak var dataSource: MessagesDataSource?

    func load(_ dataSource: MessagesDataSource) {
        self.dataSource = dataSource
    }
}

extension ConvoDisplayDelegate: MessagesDisplayDelegate {
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if let isFromCurrentSender = dataSource?.isFromCurrentSender(message: message), isFromCurrentSender {
            return UIColor.blue
        } else {
            return UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
        }
    }
}
