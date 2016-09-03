//
//  Member.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Member {
    
    var owner = ""
    var name = ""
    var nickname = ""
    
    init(owner: String, name: String, nickname: String) {
        self.owner = owner
        self.name = name
        self.nickname = nickname
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "owner": owner,
            "name": name,
            "nickname": nickname
        ]
    }
}