protocol DependencyContaining {
    var proxiesManager: ProxiesManaging { get }
    var unreadMessagesManager: UnreadMessagesManaging { get }
    var presenceManager: PresenceManaging { get }
}

struct DependencyContainer: DependencyContaining {
    static let container = DependencyContainer()
    let proxiesManager: ProxiesManaging
    let unreadMessagesManager: UnreadMessagesManaging
    let presenceManager: PresenceManaging

    private init() {
        proxiesManager = ProxiesManager()
        unreadMessagesManager = UnreadMessagesManager()
        presenceManager = PresenceManager(unreadMessagesManager)
    }
}
