import FirebaseDatabase

typealias Path = String

struct DB {
    private static let ref = Database.database().reference()

    static func makeReference(_ first: String, _ rest: String...) -> DatabaseReference? {
        return makeReference(first, rest)
    }

    static func makeReference(_ first: String, _ rest: [String]) -> DatabaseReference? {
        guard let path = Path.makePath(first, rest) else {
            return nil
        }
        return ref.child(path)
    }
}

extension DB {
    static func delete(_ first: String, _ rest: String..., completion: @escaping (Success) -> Void) {
        delete(first, rest, completion: completion)
    }

    static func delete(_ first: String, _ rest: [String], completion: @escaping (Success) -> Void) {
        guard let ref = makeReference(first, rest) else {
            completion(false)
            return
        }
        ref.removeValue { (error, _) in
            completion(error == nil)
        }
    }

    static func get(_ first: String, _ rest: String..., completion: @escaping (DataSnapshot?) -> Void) {
        get(first, rest, completion: completion)
    }

    static func get(_ first: String, _ rest: [String], completion: @escaping (DataSnapshot?) -> Void) {
        guard let ref = makeReference(first, rest) else {
            completion(nil)
            return
        }
        ref.observeSingleEvent(of: .value) { (data) in
            completion(data)
        }
    }

    static func increment(by amount: Int, at first: String, _ rest: String..., completion: @escaping ((Success) -> Void)) {
        increment(by: amount, at: first, rest, completion: completion)
    }

    static func increment(by amount: Int, at first: String, _ rest: [String], completion: @escaping ((Success) -> Void)) {
        guard let ref = makeReference(first, rest) else {
            completion(false)
            return
        }
        ref.runTransactionBlock({ (currentData) -> TransactionResult in
            if let value = currentData.value {
                var newValue = value as? Int ?? 0
                newValue += amount
                currentData.value = newValue
                return .success(withValue: currentData)
            }
            return .success(withValue: currentData)
        }) { (error, _, _) in
            if let error = error {
                fatalError(String(describing: error))
            }
            completion(error == nil)
        }
    }

    static func set(_ value: Any, at first: String, _ rest: String..., completion: @escaping ((Success) -> Void)) {
        set(value, at: first, rest, completion: completion)
    }

    static func set(_ value: Any, at first: String, _ rest: [String], completion: @escaping ((Success) -> Void)) {
        guard let ref = makeReference(first, rest) else {
            completion(false)
            return
        }
        ref.setValue(value) { (error, _) in
            completion(error == nil)
        }
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

extension Path {
    static func makePath(_ first: String, _ rest: String...) -> String? {
        return makePath(first, rest)
    }

    static func makePath(_ first: String, _ rest: [String]) -> String? {
        var children = rest
        children.insert(first, at: 0)

        let trimmed = children.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }

        for child in trimmed where child == "" || child.contains("//") {
            return nil
        }

        return trimmed.joined(separator: "/")
    }
}
