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
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as? String ?? ""
        self.ownerId = anyObject["ownerId"] as? String ?? ""
        self.icon = anyObject["icon"] as? String ?? ""
        self.nickname = anyObject["nickname"] as? String ?? ""
        self.message = anyObject["message"] as? String ?? ""
        self.created = anyObject["created"] as? Double ?? 0.0
        self.timestamp = anyObject["timestamp"] as? Double ?? 0.0
        self.convos = anyObject["convos"] as? Int ?? 0
        self.unread = anyObject["unread"] as? Int ?? 0
    }
    
    func toAnyObject() -> AnyObject {
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
