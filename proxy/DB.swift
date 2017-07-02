//
//  DatabaseUtils.swift
//  proxy
//
//  Created by Quan Vo on 6/9/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

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

    static func ref(_ path: Path) -> DatabaseReference {
        return Database.database().reference().child(path.path)
    }

    static func ref(_ path: Path?) -> DatabaseReference? {
        if let path = path {
            return ref(path)
        }
        return nil
    }

    static func get(_ first: String, _ rest: String..., completion: @escaping (DataSnapshot?) -> Void) {
        guard let path = Path(first, rest) else {
            completion(nil)
            return
        }
        ref(path).observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot)
        }
    }

    static func set(_ value: Any, at first: String, _ rest: String..., completion: @escaping ((Success) -> Void)) {
        guard let path = Path(first, rest) else {
            completion(false)
            return
        }
        ref(path).setValue(value) { (error, _) in
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

        Database.database().reference().updateChildValues(validTransactions) { (error, _) in
            completion(error == nil)
        }
    }

    static func delete(_ first: String, _ rest: String..., completion: @escaping (Success) -> Void) {
        guard let path = Path(first, rest) else {
            completion(false)
            return
        }
        ref(path).removeValue { (error, _) in
            completion(error == nil)
        }
    }

    static func increment(_ amount: Int, at first: String, _ rest: String..., completion: @escaping ((Success) -> Void)) {
        guard let path = Path(first, rest) else {
            completion(false)
            return
        }
        ref(path).runTransactionBlock( { (currentData) -> TransactionResult in
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
