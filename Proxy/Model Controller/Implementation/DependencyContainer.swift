struct DependencyContainer: DependencyContaining {
    static let container = DependencyContainer()

    let proxiesManager: ProxiesManaging = ProxiesManager()
    let unreadMessagesManager: UnreadMessagesManaging = UnreadMessagesManager()

    private init() {}
}
