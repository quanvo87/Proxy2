//
//  Proxy.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Proxy {
    
    var key = ""
    var ownerId = ""
    var timeCreated = 0.0
    var timestamp = 0.0
    var isDeleted = false
    
    init() {}
    
    init(key: String, ownerId: String, timeCreated: Double, timestamp: Double, isDeleted: Bool) {
        self.key = key
        self.ownerId = ownerId
        self.timeCreated = timeCreated
        self.timestamp = timestamp
        self.isDeleted = isDeleted
    }
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as? String ?? ""
        self.ownerId = anyObject["ownerId"] as? String ?? ""
        self.timeCreated = anyObject["timeCreated"] as? Double ?? 0.0
        self.timestamp = anyObject["timestamp"] as? Double ?? 0.0
        self.isDeleted = anyObject["isDeleted"] as? Bool ?? false
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "ownerId": ownerId,
            "timeCreated": timeCreated,
            "timestamp": timestamp,
            "isDeleted": isDeleted
        ]
    }
}
