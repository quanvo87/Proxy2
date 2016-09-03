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
    var convoNickname = ""
    var proxyNickname = ""
    var message = ""
    var timestamp = 0.0
    var unread = 0
    
    init() {}
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as? String ?? ""
        self.senderId = anyObject["senderId"] as? String ?? ""
        self.senderProxy = anyObject["senderProxy"] as? String ?? ""
        self.receiverId = anyObject["receiverId"] as? String ?? ""
        self.receiverProxy = anyObject["receiverProxy"] as? String ?? ""
        self.convoNickname = anyObject["convoNickname"] as? String ?? ""
        self.proxyNickname = anyObject["proxyNickname"] as? String ?? ""
        self.message = anyObject["message"] as? String ?? ""
        self.timestamp = anyObject["timestamp"] as? Double ?? 0.0
        self.unread = anyObject["unread"] as? Int ?? 0
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "senderId": senderId,
            "senderProxy": senderProxy,
            "receiverId": receiverId,
            "receiverProxy": receiverProxy,
            "convoNickname": convoNickname,
            "proxyNickname": proxyNickname,
            "message": message,
            "timestamp": timestamp,
            "unread": unread
        ]
    }
}