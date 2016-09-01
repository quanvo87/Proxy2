//
//  Convo.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Convo {
    
    var key = ""
    var nickname = ""
    var senderId = ""
    var senderProxy = ""
    var receiverId = ""
    var receiverProxy = ""
    var message = ""
    var timestamp = 0.0
    var unread = 0
    
    init() {}
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as? String ?? ""
        self.nickname = anyObject["nickname"] as? String ?? ""
        self.senderId = anyObject["senderId"] as? String ?? ""
        self.senderProxy = anyObject["senderProxy"] as? String ?? ""
        self.receiverId = anyObject["receiverId"] as? String ?? ""
        self.receiverProxy = anyObject["receiverProxy"] as? String ?? ""
        self.message = anyObject["message"] as? String ?? ""
        self.timestamp = anyObject["timestamp"] as? Double ?? 0.0
        self.unread = anyObject["unread"] as? Int ?? 0
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "nickname": nickname,
            "senderId": senderId,
            "senderProxy": senderProxy,
            "receiverId": receiverId,
            "receiverProxy": receiverProxy,
            "message": message,
            "timestamp": timestamp,
            "unread": unread
        ]
    }
}