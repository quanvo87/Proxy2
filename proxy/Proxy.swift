//
//  Proxy.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Proxy {
    
    let api = API.sharedInstance
    
    var owner = ""
    var icon = ""
    var name = ""
    var nickname = ""
    var message = ""
    var timestamp = NSDate().timeIntervalSince1970
    var unread = 0
    
    init() {}
    
    init(name: String) {
        self.owner = api.uid
        self.name = name
    }
    
    init(anyObject: AnyObject) {
        self.owner = anyObject["owner"] as? String ?? ""
        self.icon = anyObject["icon"] as? String ?? ""
        self.name = anyObject["name"] as? String ?? ""
        self.nickname = anyObject["nickname"] as? String ?? ""
        self.message = anyObject["message"] as? String ?? ""
        self.timestamp = anyObject["timestamp"] as? Double ?? 0.0
        self.unread = anyObject["unread"] as? Int ?? 0
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "owner": owner,
            "icon": icon,
            "name": name,
            "nickname": nickname,
            "message": message,
            "timestamp": timestamp,
            "unread": unread
        ]
    }
}