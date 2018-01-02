protocol DependencyContaining: class {
    var proxiesManager: ProxiesManaging { get }
    var unreadMessagesManager: UnreadMessagesManaging { get }
}
