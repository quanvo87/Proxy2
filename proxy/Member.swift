//
//  Member.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Member {
    
    var key = ""
    var owner = ""
    var name = ""
    var nickname = ""
    
    init(key: String, owner: String, name: String, nickname: String) {
        self.key = key
        self.owner = owner
        self.name = name
        self.nickname = nickname
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "owner": owner,
            "name": name,
            "nickname": nickname
        ]
    }
}