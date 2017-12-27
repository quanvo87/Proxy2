protocol UnreadMessagesManaging: class {
    var convosPresentIn: [String: Bool] { get set }
    var unreadMessages: [Message] { get set }
}

extension UnreadMessagesManaging {
    func enterConvo(_ convoKey: String) {
        convosPresentIn[convoKey] = true
        var untouchedMessages = [Message]()
        for message in unreadMessages {
            if message.parentConvoKey == convoKey {
                DBMessage.read(message) { _ in }
            } else {
                untouchedMessages.append(message)
            }
        }
        unreadMessages = untouchedMessages
    }

    func leaveConvo(_ convoKey: String) {
        convosPresentIn.removeValue(forKey: convoKey)
    }
}
