import MessageKit

class ConvoDisplayDelegate {
    private weak var dataSource: MessagesDataSource?
    private weak var manager: MessagesManaging?

    private var messages: [MessageType] {
        return manager?.messages ?? []
    }

    func load(dataSource: MessagesDataSource, manager: MessagesManaging) {
        self.dataSource = dataSource
        self.manager = manager
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

    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey : Any] {
        return MessageLabel.defaultAttributes
    }

    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date]
    }

    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        if indexPath.section == messages.count - 1 {
            if dataSource?.isFromCurrentSender(message: message) ?? false {
                return .bubbleTail(.bottomRight, .curved)
            } else {
                return .bubbleTail(.bottomLeft, .curved)
            }
        }
        if let nextMessage = messages[safe: indexPath.section + 1],
            nextMessage.sender != message.sender {
            if dataSource?.isFromCurrentSender(message: message) ?? false {
                return .bubbleTail(.bottomRight, .curved)
            } else {
                return .bubbleTail(.bottomLeft, .curved)
            }
        }
        return .bubble
    }
}
