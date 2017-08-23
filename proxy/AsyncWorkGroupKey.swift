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

    static func getOwnerIdAndProxyKey(fromConvo convo: Convo, asSender: Bool) -> (ownerId: String, proxyKey: String) {
        return (asSender ? convo.senderId : convo.receiverId,
                asSender ? convo.senderProxyKey : convo.receiverProxyKey)
    }
}

extension AsyncWorkGroupKey {
    func delete(_ convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        delete(at: Path.Convos, ownerId, convo.key)
        delete(at: Path.Convos, proxyKey, convo.key)
    }

    func increment(by amount: Int, forProperty property: IncrementableConvoProperty, forConvo convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        increment(by: amount, at: Path.Convos, ownerId, convo.key, property.rawValue)
        increment(by: amount, at: Path.Convos, proxyKey, convo.key, property.rawValue)
    }

    func set(_ property: SettableConvoProperty, forConvo convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        set(property.properties.value, at: Path.Convos, ownerId, convo.key, property.properties.name)
        set(property.properties.value, at: Path.Convos, proxyKey, convo.key, property.properties.name)
    }

    func set(_ convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        set(convo.toDictionary(), at: Path.Convos, ownerId, convo.key)
        set(convo.toDictionary(), at: Path.Convos, proxyKey, convo.key)
    }
}

extension AsyncWorkGroupKey {
    func increment(by amount: Int, forProperty property: IncrementableProxyProperty, forProxy proxy: Proxy) {
        increment(by: amount, forProperty: property, proxyOwner: proxy.ownerId, proxyKey: proxy.key)
    }

    func increment(by amount: Int, forProperty property: IncrementableProxyProperty, forProxyInConvo convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        increment(by: amount, forProperty: property, proxyOwner: ownerId, proxyKey: proxyKey)
    }

    func increment(by amount: Int, forProperty property: IncrementableProxyProperty, proxyOwner: String, proxyKey: String) {
        increment(by: amount, at: Path.Proxies, proxyOwner, proxyKey, property.rawValue)
    }

    func set(_ property: SettableProxyProperty, forProxy proxy: Proxy) {
        self.set(property, proxyOwner: proxy.ownerId, proxyKey: proxy.key)
    }

    func set(_ property: SettableProxyProperty, forProxyInConvo convo: Convo, asSender: Bool) {
        let (ownerId, proxyKey) = AsyncWorkGroupKey.getOwnerIdAndProxyKey(fromConvo: convo, asSender: asSender)
        set(property, proxyOwner: ownerId, proxyKey: proxyKey)
    }

    func set(_ property: SettableProxyProperty, proxyOwner: String, proxyKey: String) {
        set(property.properties.value, at: Path.Proxies, proxyOwner, proxyKey, property.properties.name)
    }
}

enum IncrementableUserProperty: String {
    case messagesReceived
    case messagesSent
    case proxiesInteractedWith
    case proxyCount
    case unread
}

extension AsyncWorkGroupKey {
    func increment(by amount: Int, forProperty property: IncrementableUserProperty, forUser uid: String) {
        increment(by: amount, at: Path.UserInfo, uid, property.rawValue)
    }
}
