import GroupWork

enum IncrementableUserProperty: String {
    case messagesReceived
    case messagesSent
    case proxiesInteractedWith
}

extension GroupWork {
    func increment(_ amount: Int, property: IncrementableUserProperty, uid: String) {
        increment(amount, at: Child.userInfo, uid, property.rawValue)
    }
}
