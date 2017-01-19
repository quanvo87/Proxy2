//
//  Proxy.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Proxy {
    
    var key = ""
    var ownerId = ""
    var icon = ""
    var nickname = ""
    var message = ""
    var created = NSDate().timeIntervalSince1970
    var timestamp = NSDate().timeIntervalSince1970
    var convos = 0
    var unread = 0
    
    init() {}
    
    init(key: String, ownerId: String) {
        self.key = key
        self.ownerId = ownerId
    }
    
    init(key: String, ownerId: String, icon: String) {
        self.key = key
        self.ownerId = ownerId
        self.icon = icon
    }
    
    init?(anyObject: AnyObject) {
        if
            let key = anyObject["key"] as? String,
            let ownerId = anyObject["ownerId"] as? String,
            let icon = anyObject["icon"] as? String,
            let nickname = anyObject["nickname"] as? String,
            let message = anyObject["message"] as? String,
            let created = anyObject["created"] as? Double,
            let timestamp = anyObject["timestamp"] as? Double,
            let convos = anyObject["convos"] as? Int,
            let unread = anyObject["unread"] as? Int {
            self.key = key
            self.ownerId = ownerId
            self.icon = icon
            self.nickname = nickname
            self.message = message
            self.created = created
            self.timestamp = timestamp
            self.convos = convos
            self.unread = unread
        } else {
            return nil
        }
    }
    
    func toAnyObject() -> Any {
        return [
            "key": key,
            "ownerId": ownerId,
            "icon": icon,
            "nickname": nickname,
            "message": message,
            "created": created,
            "timestamp": timestamp,
            "convos": convos,
            "unread": unread
        ]
    }
}
