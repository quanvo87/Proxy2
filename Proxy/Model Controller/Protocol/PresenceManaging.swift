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
    private weak var manager: UnreadMessagesManaging?

    init(_ manager: UnreadMessagesManaging) {
        self.manager = manager
    }

    func enterConvo(_ key: String) {
        presentInConvo = key
        var untouchedMessages = [Message]()
        for message in (manager?.unreadMessages) ?? [] {
            if message.parentConvoKey == key {
                DB.read(message) { _ in }
            } else {
                untouchedMessages.append(message)
            }
        }
        manager?.unreadMessages = untouchedMessages
    }
}
