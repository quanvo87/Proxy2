//
//  Proxy.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Proxy {
    
    var key = ""
//    var name = ""
    var ownerId = ""
    var timeCreated = 0.0
    var timestamp = 0.0
    
    init() {}
    
    init(key: String, ownerId: String, timeCreated: Double, timestamp: Double) {
        self.key = key
//        self.name = name
        self.ownerId = ownerId
        self.timeCreated = timeCreated
        self.timestamp = timestamp
    }
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as? String ?? ""
//        self.name = anyObject["name"] as? String ?? ""
        self.ownerId = anyObject["ownerId"] as? String ?? ""
        self.timeCreated = anyObject["timeCreated"] as? Double ?? 0.0
        self.timestamp = anyObject["timestamp"] as? Double ?? 0.0
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
//            "name": name,
            "ownerId": ownerId,
            "timeCreated": timeCreated,
            "timestamp": timestamp
        ]
    }
}
