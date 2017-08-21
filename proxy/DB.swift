import FirebaseDatabase

struct DB {
    struct Path {
        let path: String

        init?(_ first: String, _ rest: String...) {
            self.init(first, rest)
        }

        init?(_ first: String, _ rest: [String]) {
            var children = rest
            children.insert(first, at: 0)

            let trimmed = children.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }

            for child in trimmed where child == "" || child.contains("//") {
                return nil
            }
            
            path = trimmed.joined(separator: "/")
        }
    }

    struct Transaction {
        let value: Any
        let path: Path

        init?(set value: Any, at first: String, _ rest: String...) {
            guard let path = Path(first, rest) else {
                return nil
            }

            self.value = value
            self.path = path
        }
    }

    private static let ref = Database.database().reference()

    static func ref(_ first: String, _ rest: String...) -> DatabaseReference? {
        if let path = Path(first, rest) {
            return ref.child(path.path)
        }
        return nil
    }

    static func ref(_ first: String, _ rest: [String]) -> DatabaseReference? {
        if let path = Path(first, rest) {
            return ref.child(path.path)
        }
        return nil
    }
}

extension DB {
    static func get(_ first: String, _ rest: String..., completion: @escaping (DataSnapshot?) -> Void) {
        guard let ref = ref(first, rest) else {
            completion(nil)
            return
        }
        ref.observeSingleEvent(of: .value) { (data) in
            completion(data)
        }
    }

    static func set(_ value: Any, at first: String, _ rest: String..., completion: @escaping ((Success) -> Void)) {
        set(value, at: first, rest, completion: completion)
    }

    static func set(_ value: Any, at first: String, _ rest: [String], completion: @escaping ((Success) -> Void)) {
        guard let ref = ref(first, rest) else {
            completion(false)
            return
        }
        ref.setValue(value) { (error, _) in
            completion(error == nil)
        }
    }

    static func set(_ transactions: [Transaction?], completion: @escaping (Success) -> Void) {
        var validTransactions = [String: Any]()

        for transaction in transactions {
            guard
                let transaction = transaction,
                validTransactions[transaction.path.path] == nil else {
                    completion(false)
                    return
            }
            validTransactions[transaction.path.path] = transaction.value
        }

        ref.updateChildValues(validTransactions) { (error, _) in
            completion(error == nil)
        }
    }

    static func delete(_ first: String, _ rest: String..., completion: @escaping (Success) -> Void) {
        delete(first, rest, completion: completion)
    }

    static func delete(_ first: String, _ rest: [String], completion: @escaping (Success) -> Void) {
        guard let ref = ref(first, rest) else {
            completion(false)
            return
        }
        ref.removeValue { (error, _) in
            completion(error == nil)
        }
    }

    static func increment(by amount: Int, at first: String, _ rest: String..., completion: @escaping ((Success) -> Void)) {
        increment(by: amount, at: first, rest, completion: completion)
    }

    static func increment(by amount: Int, at first: String, _ rest: [String], completion: @escaping ((Success) -> Void)) {
        guard let ref = ref(first, rest) else {
            completion(false)
            return
        }
        ref.runTransactionBlock( { (currentData) -> TransactionResult in
            if let value = currentData.value {
                var newValue = value as? Int ?? 0
                newValue += amount
                currentData.value = newValue
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, _, _) in
            completion(error == nil)
        }
    }
}
