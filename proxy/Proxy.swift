//
//  Proxy.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Proxy {
    
    var globalKey = ""
    var key = ""
    var owner = ""
    var icon = ""
    var nickname = ""
    var timestamp = NSDate().timeIntervalSince1970
    var unread = 0
    var created = NSDate().timeIntervalSince1970
    
    init() {}
    
    init(globalKey: String, key: String, owner: String, icon: String) {
        self.globalKey = globalKey
        self.key = key
        self.owner = owner
        self.icon = icon
    }
    
    init(anyObject: AnyObject) {
        self.globalKey = anyObject["globalKey"] as? String ?? ""
        self.key = anyObject["key"] as? String ?? ""
        self.owner = anyObject["owner"] as? String ?? ""
        self.icon = anyObject["icon"] as? String ?? ""
        self.nickname = anyObject["nickname"] as? String ?? ""
        self.timestamp = anyObject["timestamp"] as? Double ?? 0.0
        self.unread = anyObject["unread"] as? Int ?? 0
        self.created = anyObject["created"] as? Double ?? 0.0
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "globalKey": globalKey,
            "key": key,
            "owner": owner,
            "icon": icon,
            "nickname": nickname,
            "timestamp": timestamp,
            "unread": unread,
            "created": created,
        ]
    }
}