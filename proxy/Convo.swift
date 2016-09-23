//
//  Convo.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Convo {
    
    var key = ""
    var senderId = ""
    var senderProxy = ""
    var receiverId = ""
    var receiverProxy = ""
    var timestamp = 0.0
    var didLeaveConvo = false
    var receiverDeletedProxy = false
    var senderIsBlocking = false
    var receiverIsBlocking = false
    
    init() {}
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as? String ?? ""
        self.senderId = anyObject["senderId"] as? String ?? ""
        self.senderProxy = anyObject["senderProxy"] as? String ?? ""
        self.receiverId = anyObject["receiverId"] as? String ?? ""
        self.receiverProxy = anyObject["receiverProxy"] as? String ?? ""
        self.timestamp = anyObject["timestamp"] as? Double ?? 0.0
        self.didLeaveConvo = anyObject["didLeaveConvo"] as? Bool ?? false
        self.receiverDeletedProxy = anyObject["receiverDeletedProxy"] as? Bool ?? false
        self.senderIsBlocking = anyObject["senderIsBlocking"] as? Bool ?? false
        self.receiverIsBlocking = anyObject["receiverIsBlocking"] as? Bool ?? false
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "senderId": senderId,
            "senderProxy": senderProxy,
            "receiverId": receiverId,
            "receiverProxy": receiverProxy,
            "timestamp": timestamp,
            "didLeaveConvo": didLeaveConvo,
            "receiverDeletedProxy": receiverDeletedProxy,
            "senderIsBlocking": senderIsBlocking,
            "receiverIsBlocking": receiverIsBlocking
        ]
    }
}
