protocol PresenceManaging: class {
    var presentInConvo: String { get set }
    func enterConvo(_ convoKey: String)
    func leaveConvo(_ convoKey: String)
}

class PresenceManager: PresenceManaging {
    var presentInConvo = ""
    private weak var manager: UnreadMessagesManaging?

    init(_ manager: UnreadMessagesManaging) {
        self.manager = manager
    }

    func enterConvo(_ convoKey: String) {
        presentInConvo = convoKey
        var untouchedMessages = [Message]()
        for message in (manager?.unreadMessages) ?? [] {
            if message.parentConvoKey == convoKey {
                DB.read(message) { _ in }
            } else {
                untouchedMessages.append(message)
            }
        }
        manager?.unreadMessages = untouchedMessages
    }

    func leaveConvo(_ convoKey: String) {
        presentInConvo = ""
    }
}
