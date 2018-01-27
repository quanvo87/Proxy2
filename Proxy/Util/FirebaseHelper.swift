import FirebaseDatabase

typealias Path = String

struct FirebaseHelper {
    private static let ref = FirebaseDatabase.Database.database().reference()

    static func delete(_ first: String, _ rest: String..., completion: @escaping (Bool) -> Void) {
        delete(first, rest, completion: completion)
    }

    static func delete(_ first: String, _ rest: [String], completion: @escaping (Bool) -> Void) {
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

    static func increment(_ amount: Int, at first: String, _ rest: String..., completion: @escaping (Bool) -> Void) {
        increment(amount, at: first, rest, completion: completion)
    }

    static func increment(_ amount: Int, at first: String, _ rest: [String], completion: @escaping (Bool) -> Void) {
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

    static func makeReference(_ first: String, _ rest: String...) -> DatabaseReference? {
        return makeReference(first, rest)
    }

    static func makeReference(_ first: String, _ rest: [String]) -> DatabaseReference? {
        guard let path = Path.makePath(first, rest) else {
            return nil
        }
        return ref.child(path)
    }

    static func set(_ value: Any, at first: String, _ rest: String..., completion: @escaping (Bool) -> Void) {
        set(value, at: first, rest, completion: completion)
    }

    static func set(_ value: Any, at first: String, _ rest: [String], completion: @escaping (Bool) -> Void) {
        guard let ref = makeReference(first, rest) else {
            completion(false)
            return
        }
        ref.setValue(value) { (error, _) in
            completion(error == nil)
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

        let trimmed = children.map {
            $0.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }

        for child in trimmed where child == "" || child.contains("//") {
            return nil
        }

        return trimmed.joined(separator: "/")
    }
}
