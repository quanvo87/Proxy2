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
    var senderIsBlocking = false
    var senderDidDeleteProxy = false
    var didLeaveConvo = false
    var receiverId = ""
    var receiverProxy = ""
    var receiverIsBlocking = false
    var timestamp = 0.0
    
    init() {}
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as? String ?? ""
        self.senderId = anyObject["senderId"] as? String ?? ""
        self.senderProxy = anyObject["senderProxy"] as? String ?? ""
        self.senderIsBlocking = anyObject["senderIsBlocking"] as? Bool ?? false
        self.senderDidDeleteProxy = anyObject["senderDidDeleteProxy"] as? Bool ?? false
        self.didLeaveConvo = anyObject["didLeaveConvo"] as? Bool ?? false
        self.receiverId = anyObject["receiverId"] as? String ?? ""
        self.receiverProxy = anyObject["receiverProxy"] as? String ?? ""
        self.receiverIsBlocking = anyObject["receiverIsBlocking"] as? Bool ?? false
        self.timestamp = anyObject["timestamp"] as? Double ?? 0.0
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "senderId": senderId,
            "senderProxy": senderProxy,
            "senderIsBlocking": senderIsBlocking,
            "senderDidDeleteProxy": senderDidDeleteProxy,
            "didLeaveConvo": didLeaveConvo,
            "receiverId": receiverId,
            "receiverProxy": receiverProxy,
            "receiverIsBlocking": receiverIsBlocking,
            "timestamp": timestamp
        ]
    }
}
