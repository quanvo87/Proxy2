//
//  Message.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Message {
    
    var key = ""
    var sender = ""
    var message = ""
    var timestamp = 0.0
    
    init(key: String, sender: String, message: String, timestamp: Double) {
        self.key = key
        self.sender = sender
        self.message = message
        self.timestamp = timestamp
    }
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as? String ?? ""
        self.sender = anyObject["sender"] as? String ?? ""
        self.message = anyObject["message"] as? String ?? ""
        self.timestamp = anyObject["timestamp"] as? Double ?? 0.0
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "sender": sender,
            "message": message,
            "timestamp": timestamp
        ]
    }
}