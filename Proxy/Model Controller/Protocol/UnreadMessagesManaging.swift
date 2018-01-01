protocol UnreadMessagesManaging: class {
    var convosPresentIn: [String: Bool] { get set }
    var unreadMessages: [Message] { get set }
}

extension UnreadMessagesManaging {
    // todo: instead of bool, make it a counter. or make it to where you can only be in one convo at a time
    func enterConvo(_ convoKey: String) {
        convosPresentIn[convoKey] = true
        var untouchedMessages = [Message]()
        for message in unreadMessages {
            if message.parentConvoKey == convoKey {
                DB.read(message) { _ in }
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
