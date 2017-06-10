//
//  DatabaseUtils.swift
//  proxy
//
//  Created by Quan Vo on 6/9/17.
//  Copyright © 2017 Quan Vo. All rights reserved.
//

import FirebaseDatabase

struct DB {
    // TODO: - return errors
    static func ref(_ pathNodes: String...) -> DatabaseReference {
        return ref(pathNodes)
    }

    static func ref(_ pathNodes: [String]) -> DatabaseReference {
        var path = ""
        for node in pathNodes {
            precondition(node != "")    // TODO: - return error
            path += node + "/"
        }
        return Database.database().reference().child(path)
    }

    static func get(_ pathNodes: String..., completion: @escaping (DataSnapshot) -> Void) {
        ref(pathNodes).observeSingleEvent(of: .value) { (snapshot) in
            completion(snapshot)
        }
    }

    static func set(_ value: Any, pathNodes: String..., completion: ((Error?) -> Void)? = nil) {
        ref(pathNodes).setValue(value, withCompletionBlock: { (error, _) in
            completion?(error)
        })
    }

    static func delete(_ pathNodes: String..., completion: ((Error?) -> Void)? = nil) {
        ref(pathNodes).removeValue { (error, _) in
            completion?(error)
        }
    }

    static func increment(_ amount: Int, pathNodes: String..., completion: ((Error?) -> Void)? = nil) {
        ref(pathNodes).runTransactionBlock( { (currentData) -> TransactionResult in
            if let value = currentData.value {
                var newValue = value as? Int ?? 0
                newValue += amount
                currentData.value = newValue
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        }) { (error, _, _) in
            completion?(error)
        }
    }
}
