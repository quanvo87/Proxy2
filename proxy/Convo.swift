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
    var senderNickname = ""
    var receiverId = ""
    var receiverProxy = ""
    var receiverNickname = ""
    var receiverIcon = ""
    var message = ""
    var leftConvo = false
    var senderDeletedProxy = false
    var senderIsBlocking = false
    var receiverDeletedProxy = false
    var receiverIsBlocking = false
    var timestamp = 0.0
    var unread = 0
    
    init() {}
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as? String ?? ""
        self.senderId = anyObject["senderId"] as? String ?? ""
        self.senderProxy = anyObject["senderProxy"] as? String ?? ""
        self.senderNickname = anyObject["senderNickname"] as? String ?? ""
        self.receiverId = anyObject["receiverId"] as? String ?? ""
        self.receiverProxy = anyObject["receiverProxy"] as? String ?? ""
        self.receiverNickname = anyObject["receiverNickname"] as? String ?? ""
        self.receiverIcon = anyObject["receiverIcon"] as? String ?? ""
        self.message = anyObject["message"] as? String ?? ""
        self.leftConvo = anyObject["leftConvo"] as? Bool ?? false
        self.senderDeletedProxy = anyObject["senderDeletedProxy"] as? Bool ?? false
        self.senderIsBlocking = anyObject["senderIsBlocking"] as? Bool ?? false
        self.receiverDeletedProxy = anyObject["receiverDeletedProxy"] as? Bool ?? false
        self.receiverIsBlocking = anyObject["receiverIsBlocking"] as? Bool ?? false
        self.timestamp = anyObject["timestamp"] as? Double ?? 0.0
        self.unread = anyObject["unread"] as? Int ?? 0
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "senderId": senderId,
            "senderProxy": senderProxy,
            "senderNickname": senderNickname,
            "receiverId": receiverId,
            "receiverProxy": receiverProxy,
            "receiverNickname": receiverNickname,
            "receiverIcon" : receiverIcon,
            "message": message,
            "leftConvo": leftConvo,
            "senderDeletedProxy": senderDeletedProxy,
            "senderIsBlocking": senderIsBlocking,
            "receiverDeletedProxy": receiverDeletedProxy,
            "receiverIsBlocking": receiverIsBlocking,
            "timestamp": timestamp,
            "unread": unread
        ]
    }
}
