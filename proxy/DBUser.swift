enum IncrementableUserProperty: String {
    case messagesReceived
    case messagesSent
    case proxiesInteractedWith
    case unreadCount    // TODO: remove
}

extension AsyncWorkGroupKey {
    func increment(by amount: Int, forProperty property: IncrementableUserProperty, forUser uid: String) {
        increment(by: amount, at: Child.UserInfo, uid, property.rawValue)
    }
}
