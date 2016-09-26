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
    var senderDidDeleteProxy = false
    var senderIsBlocking = false
    var receiverId = ""
    var receiverProxy = ""
    var receiverDidDeleteProxy = false
    var receiverIsBlocking = false
    var didLeaveConvo = false
    var timestamp = 0.0
    
    init() {}
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as? String ?? ""
        self.senderId = anyObject["senderId"] as? String ?? ""
        self.senderProxy = anyObject["senderProxy"] as? String ?? ""
        self.senderDidDeleteProxy = anyObject["senderDidDeleteProxy"] as? Bool ?? false
        self.senderIsBlocking = anyObject["senderIsBlocking"] as? Bool ?? false
        self.receiverId = anyObject["receiverId"] as? String ?? ""
        self.receiverProxy = anyObject["receiverProxy"] as? String ?? ""
        self.receiverDidDeleteProxy = anyObject["receiverDidDeleteProxy"] as? Bool ?? false
        self.receiverIsBlocking = anyObject["receiverIsBlocking"] as? Bool ?? false
        self.didLeaveConvo = anyObject["didLeaveConvo"] as? Bool ?? false
        self.timestamp = anyObject["timestamp"] as? Double ?? 0.0
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "senderId": senderId,
            "senderProxy": senderProxy,
            "senderDidDeleteProxy": senderDidDeleteProxy,
            "senderIsBlocking": senderIsBlocking,
            "receiverId": receiverId,
            "receiverProxy": receiverProxy,
            "receiverDeletedProxy": receiverDidDeleteProxy,
            "receiverIsBlocking": receiverIsBlocking,
            "didLeaveConvo": didLeaveConvo,
            "timestamp": timestamp
        ]
    }
}
