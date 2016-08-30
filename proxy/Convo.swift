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
    var members = ""
    var message = ""
    var timestamp = 0.0
    var unread = 0
    
    init() {}
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as! String
        self.nickname = anyObject["nickname"] as! String
        self.members = anyObject["members"] as! String
        self.message = anyObject["message"] as! String
        self.timestamp = anyObject["timestamp"] as! NSTimeInterval
        self.unread = anyObject["unread"] as! Int
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "nickname": nickname,
            "members": members,
            "message": message,
            "timestamp": timestamp,
            "unread": unread
        ]
    }
}