import MessageKit

class ConvoDataSource {
    private weak var convoManager: ConvoManaging?
    private weak var iconManager: IconManaging?
    private weak var messagesManager: MessagesManaging?

    private var convo: Convo {
        return convoManager?.convo ?? Convo()
    }

    private var icons: [String: UIImage] {
        return iconManager?.icons ?? [:]
    }

    private var messages: [MessageType] {
        return messagesManager?.messages ?? []
    }

    func load(convoManager: ConvoManaging, iconManager: IconManaging, messagesManager: MessagesManaging) {
        self.convoManager = convoManager
        self.iconManager = iconManager
        self.messagesManager = messagesManager
    }
}

extension ConvoDataSource: MessagesDataSource {
    func avatar(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Avatar {
        if indexPath.section == messages.count - 1 {
            return makeAvatar(message)
        }
        if let nextMessage = messages[safe: indexPath.section + 1],
            nextMessage.sender != message.sender {
            return makeAvatar(message)
        }
        return Avatar(image: icons["blank"], initials: "")
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section == 0 {
            return makeDisplayName(message)
        }
        if let previousMessage = messages[safe: indexPath.section - 1],
            previousMessage.sender != message.sender {
            return makeDisplayName(message)
        }
        return nil
    }

    func currentSender() -> Sender {
        return Sender(id: convo.senderId, displayName: convo.senderDisplayName)
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messagesManager?.messages[safe: indexPath.section] ?? Message()
    }

    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messagesManager?.messages.count ?? 0
    }
}

private extension ConvoDataSource {
    func makeAvatar(_ message: MessageType) -> Avatar {
        if isFromCurrentSender(message: message) {
            return Avatar(image: icons[convo.senderProxyKey],
                          initials: convo.senderDisplayName.getFirstNChars(2).capitalized)
        } else {
            return Avatar(image: icons[convo.receiverProxyKey],
                          initials: convo.receiverDisplayName.getFirstNChars(2).capitalized)
        }
    }

    func makeDisplayName(_ message: MessageType) -> NSAttributedString {
        return NSAttributedString(string: isFromCurrentSender(message: message) ? convo.senderDisplayName : convo.receiverDisplayName,
                                  attributes: [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }
}
