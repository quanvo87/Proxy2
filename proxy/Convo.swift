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
    var message = ""
    var timestamp = 0.0
    
    init() {}
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as! String
        self.nickname = anyObject["nickname"] as! String
        self.message = anyObject["message"] as! String
        self.timestamp = anyObject["timestamp"] as! NSTimeInterval
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "nickname": nickname,
            "message": message,
            "timestamp": timestamp
        ]
    }
}