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
    func set(_ value: Any, at first: String, _ rest: String...) {
        startWork()
        DB.set(value, at: first, rest) { (success) in
            self.finishWork(withResult: success)
        }
    }

    func increment(by amount: Int, at first: String, _ rest: String...) {
        startWork()
        DB.increment(by: amount, at: first, rest) { (success) in
            self.finishWork(withResult: success)
        }
    }
}

extension AsyncWorkGroupKey {
    func increment(by amount: Int, forProperty property: IncrementableConvoProperty, forConvo convo: Convo, asSender: Bool) {
        let ownderId = asSender ? convo.senderId : convo.receiverId
        let proxyKey = asSender ? convo.senderProxyKey : convo.receiverProxyKey

        increment(by: amount, at: Path.Convos, ownderId, convo.key, property.rawValue)
        increment(by: amount, at: Path.Convos, proxyKey, convo.key, property.rawValue)
    }

    func set(_ property: SettableConvoProperty, forConvo convo: Convo, asSender: Bool) {
        let ownderId = asSender ? convo.senderId : convo.receiverId
        let proxyKey = asSender ? convo.senderProxyKey : convo.receiverProxyKey

        set(property.properties.newValue, at: Path.Convos, ownderId, convo.key, property.properties.name)
        set(property.properties.newValue, at: Path.Convos, proxyKey, convo.key, property.properties.name)
    }
}

extension AsyncWorkGroupKey {
    func increment(by amount: Int, forProperty property: IncrementableProxyProperty, forProxy proxy: Proxy) {
        increment(by: amount, forProperty: property, proxyOwner: proxy.ownerId, proxyKey: proxy.key)
    }

    func increment(by amount: Int, forProperty property: IncrementableProxyProperty, forReceiverProxyInConvo convo: Convo) {
        increment(by: amount, forProperty: property, proxyOwner: convo.receiverId, proxyKey: convo.receiverProxyKey)
    }

    func increment(by amount: Int, forProperty property: IncrementableProxyProperty, forSenderProxyInConvo convo: Convo) {
        increment(by: amount, forProperty: property, proxyOwner: convo.senderId, proxyKey: convo.senderProxyKey)
    }

    func increment(by amount: Int, forProperty property: IncrementableProxyProperty, proxyOwner: String, proxyKey: String) {
        increment(by: amount, at: Path.Proxies, proxyOwner, proxyKey, property.rawValue)
    }

    func set(_ property: SettableProxyProperty, forProxy proxy: Proxy) {
        self.set(property, proxyOwner: proxy.ownerId, proxyKey: proxy.key)
    }

    func set(_ property: SettableProxyProperty, forReceiverProxyInConvo convo: Convo) {
        self.set(property, proxyOwner: convo.receiverId, proxyKey: convo.receiverProxyKey)
    }

    func set(_ property: SettableProxyProperty, forSenderProxyInConvo convo: Convo) {
        self.set(property, proxyOwner: convo.senderId, proxyKey: convo.senderProxyKey)
    }

    func set(_ property: SettableProxyProperty, proxyOwner: String, proxyKey: String) {
        set(property.properties.newValue, at: Path.Proxies, proxyOwner, proxyKey, property.properties.name)
    }
}
