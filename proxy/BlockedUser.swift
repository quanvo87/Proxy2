//
//  BlockedUser.swift
//  proxy
//
//  Created by Quan Vo on 11/5/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct BlockedUser {
    
    var id: String
    var icon: String
    var name: String
    var nickname: String
    var created = NSDate().timeIntervalSince1970
    
    init(id: String, icon: String, name: String, nickname: String) {
        self.id = id
        self.icon = icon
        self.name = name
        self.nickname = nickname
    }
    
    init?(anyObject: AnyObject) {
        if
            let id = anyObject["id"] as? String,
            let icon = anyObject["icon"] as? String,
            let name = anyObject["name"] as? String,
            let nickname = anyObject["nickname"] as? String,
            let created = anyObject["created"] as? Double {
            self.id = id
            self.icon = icon
            self.name = name
            self.nickname = nickname
            self.created = created
        } else {
            return nil
        }
    }
    
    func toAnyObject() -> AnyObject {
        return [
           "id": id,
           "icon": icon,
           "name": name,
           "nickname": nickname,
           "created": created
        ]
    }
}
