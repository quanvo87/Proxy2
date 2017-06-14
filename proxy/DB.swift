//
//  DatabaseUtils.swift
//  proxy
//
//  Created by Quan Vo on 6/9/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

struct DB {
    typealias Path = String
    typealias Transactions = [Path: Any]

    static func path(_ children: String...) throws  -> Path {
        return try path(children)
    }

    static func path(_ children: [String]) throws -> Path {
        for child in children where child == "" {
            assertionFailure()
            throw ProxyError.unknown
        }
        return children.joined(separator: "/")
    }

    static func ref(_ children: String...) -> DatabaseReference? {
        return ref(children)
    }

    static func ref(_ children: [String]) -> DatabaseReference? {
        do {
            let path = try DB.path(children)
            return Database.database().reference().child(path)
        } catch {
            assertionFailure()
            return nil
        }
    }

    static func get(_ children: String..., completion: @escaping (DataSnapshot?) -> Void) {
        guard let ref = ref(children) else {
            assertionFailure()
            completion(nil)
            return
        }
        ref.observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot)
        }
    }

    static func set(_ value: Any, children: String..., completion: @escaping ((Success) -> Void)) {
        guard let ref = ref(children) else {
            assertionFailure()
            completion(false)
            return
        }
        ref.setValue(value) { (error, _) in
            assert(error == nil, String(describing: error))
            completion(error == nil)
        }
    }

    static func set(_ transactions: Transactions, completion: @escaping (Success) -> Void) {
        Database.database().reference().updateChildValues(transactions) { (error, _) in
            assert(error == nil, String(describing: error))
            completion(error == nil)
        }
    }

    static func delete(_ children: String..., completion: @escaping (Success) -> Void) {
        guard let ref = ref(children) else {
            assertionFailure()
            completion(false)
            return
        }
        ref.removeValue { (error, _) in
            completion(error == nil)
        }
    }

    static func increment(_ amount: Int, children: String..., completion: @escaping (Success) -> Void) {
        guard let ref = ref(children) else {
            assertionFailure()
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
            assert(error == nil, String(describing: error))
            completion(error == nil)
        }
    }
}
