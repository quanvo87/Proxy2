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
        leaveWorkGroup()
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

    private func leaveWorkGroup() {
        Shared.shared.asyncWorkGroups[self]?.group.leave()
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
