protocol DependencyContaining {
    var proxiesManager: ProxiesManaging { get }
    var presenceManager: PresenceManaging { get }
    var unreadMessagesManager: UnreadMessagesManaging { get }
}

struct DependencyContainer: DependencyContaining {
    static let container = DependencyContainer()

    let proxiesManager: ProxiesManaging = ProxiesManager()
    let presenceManager: PresenceManaging = PresenceManager()
    let unreadMessagesManager: UnreadMessagesManaging = UnreadMessagesManager()

    private init() {}
}
