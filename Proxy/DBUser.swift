enum IncrementableUserProperty: String {
    case messagesReceived
    case messagesSent
    case proxiesInteractedWith
}

extension AsyncWorkGroupKey {
    func increment(by amount: Int, forProperty property: IncrementableUserProperty, forUser uid: String) {
        increment(by: amount, at: Child.userInfo, uid, property.rawValue)
    }
}