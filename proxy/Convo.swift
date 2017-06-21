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

    init?(_ json: AnyObject) {
        guard
            let key = json["key"] as? String,
            let senderId = json["senderId"] as? String,
            let senderProxyKey = json["senderProxyKey"] as? String,
            let senderProxyName = json["senderProxyName"] as? String,
            let senderNickname = json["senderNickname"] as? String,
            let receiverId = json["receiverId"] as? String,
            let receiverProxyKey = json["receiverProxyKey"] as? String,
            let receiverProxyName = json["receiverProxyName"] as? String,
            let receiverNickname = json["receiverNickname"] as? String,
            let icon = json["icon"] as? String,
            let message = json["message"] as? String,
            let senderLeftConvo = json["senderLeftConvo"] as? Bool,
            let senderIsBlocking = json["senderIsBlocking"] as? Bool,
            let receiverLeftConvo = json["receiverLeftConvo"] as? Bool,
            let receiverIsBlocking = json["receiverIsBlocking"] as? Bool,
            let receiverDeletedProxy = json["receiverDeletedProxy"] as? Bool,
            let timestamp = json["timestamp"] as? Double,
            let unread = json["unread"] as? Int else {
                return nil
        }
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
    }

    func toJSON() -> Any {
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

extension Convo: Equatable {
    static func ==(_ lhs: Convo, _ rhs: Convo) -> Bool {
        return
            lhs.key == rhs.key &&
            lhs.senderId == rhs.senderId &&
            lhs.senderProxyKey == rhs.senderProxyKey &&
            lhs.senderProxyName == rhs.senderProxyName &&
            lhs.senderNickname == rhs.senderNickname &&
            lhs.receiverId == rhs.receiverId &&
            lhs.receiverProxyKey == rhs.receiverProxyKey &&
            lhs.receiverProxyName == rhs.receiverProxyName &&
            lhs.receiverNickname == rhs.receiverNickname &&
            lhs.icon == rhs.icon &&
            lhs.message == rhs.message &&
            lhs.senderLeftConvo == rhs.senderLeftConvo &&
            lhs.senderIsBlocking == rhs.senderIsBlocking &&
            lhs.receiverDeletedProxy == rhs.receiverDeletedProxy &&
            lhs.timestamp.rounded() == rhs.timestamp.rounded() &&
            lhs.unread == rhs.unread
    }
}
