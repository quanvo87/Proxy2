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
    var senderProxyKey = ""
    var senderProxyName = ""
    var senderNickname = ""
    var receiverId = ""
    var receiverProxyKey = ""
    var receiverProxyName = ""
    var receiverNickname = ""
    var icon = ""
    var message = ""
    var senderLeftConvo = true
    var senderIsBlocking = false
    var receiverLeftConvo = true
    var receiverIsBlocking = false
    var receiverDeletedProxy = false
    var timestamp = 0.0
    var unread = 0
    
    init() {}
    
    init?(anyObject: AnyObject) {
        if
            let key = anyObject["key"] as? String,
            let senderId = anyObject["senderId"] as? String,
            let senderProxyKey = anyObject["senderProxyKey"] as? String,
            let senderProxyName = anyObject["senderProxyName"] as? String,
            let senderNickname = anyObject["senderNickname"] as? String,
            let receiverId = anyObject["receiverId"] as? String,
            let receiverProxyKey = anyObject["receiverProxyKey"] as? String,
            let receiverProxyName = anyObject["receiverProxyName"] as? String,
            let receiverNickname = anyObject["receiverNickname"] as? String,
            let icon = anyObject["icon"] as? String,
            let message = anyObject["message"] as? String,
            let senderLeftConvo = anyObject["senderLeftConvo"] as? Bool,
            let senderIsBlocking = anyObject["senderIsBlocking"] as? Bool,
            let receiverLeftConvo = anyObject["receiverLeftConvo"] as? Bool,
            let receiverIsBlocking = anyObject["receiverIsBlocking"] as? Bool,
            let receiverDeletedProxy = anyObject["receiverDeletedProxy"] as? Bool,
            let timestamp = anyObject["timestamp"] as? Double,
            let unread = anyObject["unread"] as? Int {
            self.key = key
            self.senderId = senderId
            self.senderProxyKey = senderProxyKey
            self.senderProxyName = senderProxyName
            self.senderNickname = senderNickname
            self.receiverId = receiverId
            self.receiverProxyKey = receiverProxyKey
            self.receiverProxyName = receiverProxyName
            self.receiverNickname = receiverNickname
            self.icon = icon
            self.message = message
            self.senderLeftConvo = senderLeftConvo
            self.senderIsBlocking = senderIsBlocking
            self.receiverLeftConvo = receiverLeftConvo
            self.receiverIsBlocking = receiverIsBlocking
            self.receiverDeletedProxy = receiverDeletedProxy
            self.timestamp = timestamp
            self.unread = unread
        } else {
            return nil
        }
    }
    
    func toAnyObject() -> Any {
        return [
            "key": key,
            "senderId": senderId,
            "senderProxyKey": senderProxyKey,
            "senderProxyName": senderProxyName,
            "senderNickname": senderNickname,
            "receiverId": receiverId,
            "receiverProxyKey": receiverProxyKey,
            "receiverProxyName": receiverProxyName,
            "receiverNickname": receiverNickname,
            "icon": icon,
            "message": message,
            "senderLeftConvo": senderLeftConvo,
            "senderIsBlocking": senderIsBlocking,
            "receiverLeftConvo": receiverLeftConvo,
            "receiverIsBlocking": receiverIsBlocking,
            "receiverDeletedProxy": receiverDeletedProxy,
            "timestamp": timestamp,
            "unread": unread
        ]
    }
}
