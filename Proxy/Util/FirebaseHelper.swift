import FirebaseDatabase

typealias DataCallback = (Result<DataSnapshot, Error>) -> Void
typealias ErrorCallback = (Error?) -> Void

enum FirebaseHelperError: Error {
    case invalidPath

    var localizedDescription: String {
        switch self {
        case .invalidPath:
            return "Attempted to read the database at an invalid location."
        }
    }
}

//enum Result<T, Error> {
//    case success(T)
//    case failure(Error)
//}

struct FirebaseHelper {
    private let ref: DatabaseReference

    init(_ ref: DatabaseReference) {
        self.ref = ref
    }

    func delete(_ first: String, _ rest: String..., completion: @escaping ErrorCallback) {
        delete(first, rest, completion: completion)
    }

    func delete(_ first: String, _ rest: [String], completion: @escaping ErrorCallback) {
        do {
            try makeReference(first, rest).removeValue { (error, _) in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }

    func get(_ first: String, _ rest: String..., completion: @escaping DataCallback) {
        get(first, rest, completion: completion)
    }

    func get(_ first: String, _ rest: [String], completion: @escaping DataCallback) {
        do {
            try makeReference(first, rest).observeSingleEvent(of: .value) { (data) in
                completion(.success(data))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func increment(_ amount: Int, at first: String, _ rest: String..., completion: @escaping ErrorCallback) {
        increment(amount, at: first, rest, completion: completion)
    }

    func increment(_ amount: Int, at first: String, _ rest: [String], completion: @escaping ErrorCallback) {
        do {
            try makeReference(first, rest).runTransactionBlock({ (currentData) -> TransactionResult in
                if let value = currentData.value {
                    var newValue = value as? Int ?? 0
                    newValue += amount
                    currentData.value = newValue
                    return .success(withValue: currentData)
                }
                return .success(withValue: currentData)
            }) { (error, _, _) in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }

    func makeReference(_ first: String, _ rest: String...) throws -> DatabaseReference {
        return try makeReference(first, rest)
    }

    func makeReference(_ first: String, _ rest: [String]) throws -> DatabaseReference {
        do {
            return try ref.child(String.makePath(first, rest))
        } catch {
            throw error
        }
    }

    func set(_ value: Any, at first: String, _ rest: String..., completion: @escaping ErrorCallback) {
        set(value, at: first, rest, completion: completion)
    }

    func set(_ value: Any, at first: String, _ rest: [String], completion: @escaping ErrorCallback) {
        do {
            try makeReference(first, rest).setValue(value) { (error, _) in
                completion(error)
            }
        } catch {
            completion(error)
        }
    }
}

private extension String {
    static func makePath(_ first: String, _ rest: String...) throws -> String {
        return try makePath(first, rest)
    }

    static func makePath(_ first: String, _ rest: [String]) throws -> String {
        var children = rest
        children.insert(first, at: 0)
        let trimmedChildren = children.map {
            $0.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        }
        try trimmedChildren.forEach {
            guard $0 != "" && !$0.contains("//") else {
                throw FirebaseHelperError.invalidPath
            }
        }
        return trimmedChildren.joined(separator: "/")
    }
}
