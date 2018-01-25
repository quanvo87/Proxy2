protocol PresenceManaging: class {
    var presentInConvo: String { get set }
    func enterConvo(_ key: String)
}

extension PresenceManaging {
    func leaveConvo(_ key: String) {
        presentInConvo = ""
    }
}

class PresenceManager: PresenceManaging {
    var presentInConvo = ""
    private let database = Firebase()
    private weak var manager: UnreadMessagesManaging?

    func enterConvo(_ key: String) {
        guard let unreadMessages = manager?.unreadMessages else {
            return
        }
        presentInConvo = key
        var untouchedMessages = [Message]()
        for message in unreadMessages {
            if message.parentConvoKey == key {
                database.read(message, at: Date()) { _ in }
            } else {
                untouchedMessages.append(message)
            }
        }
        manager?.unreadMessages = untouchedMessages
    }

    func load(_ manager: UnreadMessagesManaging) {
        self.manager = manager
    }
}
