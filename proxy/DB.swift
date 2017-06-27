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
            var children = rest
            children.insert(first, at: 0)

            let trimmed = children.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }

            for child in trimmed where child == "" || child.contains("//") {
                return nil
            }
            
            path = trimmed.joined(separator: "/")
        }
    }

    typealias Transaction = (key: Path?, value: Any)

//    static func path(first: String, rest: String...) -> Path? {
//        var children = rest
//        children.insert(first, at: 0)
//        return path(children)
//    }
//
//    private static func path(_ children: [String]) -> Path? {
//        let trimmed = children.map { $0.trimmingCharacters(in: CharacterSet(charactersIn: "/")) }
//
//        for child in trimmed where child == "" || child.contains("//") {
//            return nil
//        }
//
//        return trimmed.joined(separator: "/")
//    }

//    static func ref(_ children: String...) -> DatabaseReference? {
//        return ref(children)
//    }

    static func ref(_ path: Path) -> DatabaseReference {
        return Database.database().reference().child(path.path)
    }

    static func get(_ path: Path?, completion: @escaping (DataSnapshot?) -> Void) {
        guard let path = path else {
            completion(nil)
            return
        }
        ref(path).observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot)
        }
    }

    static func set(_ value: Any, path: Path?, completion: @escaping ((Success) -> Void)) {
        guard let path = path else {
            completion(nil)
            return
        }
        ref(path).setValue(value) { (error, _) in
            completion(error == nil)
        }
    }

    static func set(_ transactions: [Transaction], completion: @escaping (Success) -> Void) {
        var validTransactions = [String: Any]()

        for transaction in transactions {
            guard let path = transaction.key else {
                completion(false)
                return
            }
            guard validTransactions[path] == nil else {
                completion(false)
                return
            }
            validTransactions[path] = transaction.value
        }

        Database.database().reference().updateChildValues(validTransactions) { (error, _) in
            completion(error == nil)
        }
    }

    static func delete(_ path: Path?, completion: @escaping (Success) -> Void) {
        guard let path = path else {
            completion(nil)
            return
        }
        ref(path).removeValue { (error, _) in
            completion(error == nil)
        }
    }

    static func increment(_ amount: Int, path: Path?, completion: ((Success) -> Void)? = nil) {
        guard let path = path else {
            completion(nil)
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
            completion?(error == nil)
        }
    }
}
