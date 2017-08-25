typealias AsyncWorkGroupKey = String

extension AsyncWorkGroupKey {
    var workResult: Success {
        return Shared.shared.asyncWorkGroups[self]?.result ?? false
    }

    init() {
        let key = UUID().uuidString
        Shared.shared.asyncWorkGroups[key] = (DispatchGroup(), true)
        self = key
    }

    static func makeAsyncWorkGroupKey() -> AsyncWorkGroupKey {
        return AsyncWorkGroupKey()
    }

    func finishWork(withResult result: Success = true) {
        setWorkResult(result)
        Shared.shared.asyncWorkGroups[self]?.group.leave()
    }

    func finishWorkGroup() {
        Shared.shared.asyncWorkGroups.removeValue(forKey: self)
    }

    func notify(completion: @escaping () -> Void) {
        Shared.shared.asyncWorkGroups[self]?.group.notify(queue: .main) {
            completion()
        }
    }

    @discardableResult
    func setWorkResult(_ result: Success) -> Success {
        let result = Shared.shared.asyncWorkGroups[self]?.result ?? false && result
        Shared.shared.asyncWorkGroups[self]?.result = result
        return result
    }

    func startWork() {
        Shared.shared.asyncWorkGroups[self]?.group.enter()
    }
}

extension AsyncWorkGroupKey {
    static func getOwnerIdAndProxyKey(fromConvo convo: Convo, asSender: Bool) -> (ownerId: String, proxyKey: String) {
        return (asSender ? convo.senderId : convo.receiverId,
                asSender ? convo.senderProxyKey : convo.receiverProxyKey)
    }
    
    func delete(at first: String, _ rest: String...) {
        startWork()
        DB.delete(first, rest) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func increment(by amount: Int, at first: String, _ rest: String...) {
        startWork()
        DB.increment(by: amount, at: first, rest) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func set(_ value: Any, at first: String, _ rest: String...) {
        startWork()
        DB.set(value, at: first, rest) { (success) in
            self.finishWork(withResult: success)
        }
    }
}

extension AsyncWorkGroupKey {
    func delete(_ convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        delete(at: Child.Convos, ownerId, convo.key)
        delete(at: Child.Convos, proxyKey, convo.key)
    }

    func increment(by amount: Int, forProperty property: IncrementableConvoProperty, forConvo convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        increment(by: amount, forProperty: property, forConvoWithKey: convo.key, ownerId: ownerId, proxyKey: proxyKey)
    }

    func increment(by amount: Int, forProperty property: IncrementableConvoProperty, forConvoWithKey key: String, ownerId: String, proxyKey: String) {
        increment(by: amount, at: Child.Convos, ownerId, key, property.rawValue)
        increment(by: amount, at: Child.Convos, proxyKey, key, property.rawValue)
    }

    func set(_ convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        set(convo.toDictionary(), at: Child.Convos, ownerId, convo.key)
        set(convo.toDictionary(), at: Child.Convos, proxyKey, convo.key)
    }
    
    func set(_ property: SettableConvoProperty, forConvo convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        set(property.properties.value, at: Child.Convos, ownerId, convo.key, property.properties.name)
        set(property.properties.value, at: Child.Convos, proxyKey, convo.key, property.properties.name)
    }
}

extension AsyncWorkGroupKey {
    func set(_ property: SettableMessageProperty, forMessage message: Message) {
        set(property.properties.value, at: Child.Messages, message.parentConvo, message.key, property.properties.name)
    }
}

extension AsyncWorkGroupKey {
    func increment(by amount: Int, forProperty property: IncrementableProxyProperty, forProxy proxy: Proxy) {
        increment(by: amount, forProperty: property, forProxyWithKey: proxy.key, ownerId: proxy.ownerId)
    }

    func increment(by amount: Int, forProperty property: IncrementableProxyProperty, forProxyInConvo convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        increment(by: amount, forProperty: property, forProxyWithKey: proxyKey, ownerId: ownerId)
    }

    func increment(by amount: Int, forProperty property: IncrementableProxyProperty, forProxyWithKey key: String, ownerId: String) {
        increment(by: amount, at: Child.Proxies, ownerId, key, property.rawValue)
    }

    func set(_ property: SettableProxyProperty, forProxy proxy: Proxy) {
        set(property, forProxyWithKey: proxy.key, proxyOwner: proxy.ownerId)
    }

    func set(_ property: SettableProxyProperty, forProxyInConvo convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        set(property, forProxyWithKey: proxyKey, proxyOwner: ownerId)
    }

    func set(_ property: SettableProxyProperty, forProxyWithKey key: String, proxyOwner: String) {
        set(property.properties.value, at: Child.Proxies, proxyOwner, key, property.properties.name)
    }
}

enum IncrementableUserProperty: String {
    case messagesReceived
    case messagesSent
    case proxiesInteractedWith
    case proxyCount
    case unreadCount
}

extension AsyncWorkGroupKey {
    func increment(by amount: Int, forProperty property: IncrementableUserProperty, forUser uid: String) {
        increment(by: amount, at: Child.UserInfo, uid, property.rawValue)
    }
}
