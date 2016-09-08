//
//  Proxy.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Proxy {
    
    let api = API.sharedInstance
    
    var globalKey = ""
    var key = ""
    var owner = ""
    var icon = ""
    var nickname = ""
    var timestamp = NSDate().timeIntervalSince1970
    var unread = false
    
    init() {}
    
    init(globalKey: String, key: String) {
        self.globalKey = globalKey
        self.key = key
        self.owner = api.uid
    }
    
    init(anyObject: AnyObject) {
        self.globalKey = anyObject["globalKey"] as? String ?? ""
        self.key = anyObject["key"] as? String ?? ""
        self.owner = anyObject["owner"] as? String ?? ""
        self.icon = anyObject["icon"] as? String ?? ""
        self.nickname = anyObject["nickname"] as? String ?? ""
        self.timestamp = anyObject["timestamp"] as? Double ?? 0.0
        self.unread = anyObject["unread"] as? Bool ?? false
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "globalKey": globalKey,
            "key": key,
            "owner": owner,
            "icon": icon,
            "nickname": nickname,
            "timestamp": timestamp,
            "unread": unread
        ]
    }
}