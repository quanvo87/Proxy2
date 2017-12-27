protocol UnreadMessagesManaging: class {
    var convosPresentIn: [String: Bool] { get set }
    var unreadMessages: [Message] { get set }
}

extension UnreadMessagesManaging {
    func enterConvo(_ convoKey: String) {
        convosPresentIn[convoKey] = true
        for message in unreadMessages where message.parentConvoKey == convoKey {
            DBMessage.read(message) { (success) in
                if success, let index = self.unreadMessages.index(of: message) {
                    self.unreadMessages.remove(at: index)
                }
            }
        }
    }

    func leaveConvo(_ convoKey: String) {
        convosPresentIn.removeValue(forKey: convoKey)
    }
}
