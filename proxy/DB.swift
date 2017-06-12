//
//  DatabaseUtils.swift
//  proxy
//
//  Created by Quan Vo on 6/9/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

struct DB {
    typealias Success = Bool
    typealias Path = String
    typealias Transactions = [Path: Any]

    static func path(_ nodes: String...) -> Path {
        return path(nodes)
    }

    static func path(_ nodes: [String]) -> Path {
        for node in nodes where node == "" {
            return ""
        }
        return nodes.joined(separator: "/")
    }

    static func ref(_ nodes: String...) -> DatabaseReference? {
        return ref(nodes)
    }

    static func ref(_ nodes: [String]) -> DatabaseReference? {
        let path = DB.path(nodes)
        guard path != "" else {
            return nil
        }
        return Database.database().reference().child(path)
    }

    static func get(_ pathNodes: String..., completion: @escaping (DataSnapshot?) -> Void) {
        guard let ref = ref(pathNodes) else {
            completion(nil)
            return
        }
        ref.observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot)
        }
    }

    static func set(_ value: Any, pathNodes: String..., completion: @escaping ((Success) -> Void)) {
        guard let ref = ref(pathNodes) else {
            completion(false)
            return
        }
        ref.setValue(value) { (error, _) in
            completion(error == nil)
        }
    }

    static func set(_ transactions: Transactions, completion: @escaping (Success) -> Void) {
        for paths in transactions.keys where paths == "" {
            completion(false)
            return
        }
        Database.database().reference().updateChildValues(transactions) { (error, _) in
            completion(error == nil)
        }
    }

    static func delete(_ pathNodes: String..., completion: @escaping (Success) -> Void) {
        guard let ref = ref(pathNodes) else {
            completion(false)
            return
        }
        ref.removeValue { (error, _) in
            completion(error == nil)
        }
    }

    static func increment(_ amount: Int, pathNodes: String..., completion: @escaping (Success) -> Void) {
        guard let ref = ref(pathNodes) else {
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
