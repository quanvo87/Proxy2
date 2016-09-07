//
//  Proxy.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Proxy {
    
    let api = API.sharedInstance
    
    var key = ""
    var owner = ""
    var name = ""
    var icon = ""
    var nickname = ""
    
    init() {}
    
    init(key: String, name: String) {
        self.key = key
        self.owner = api.uid
        self.name = name
    }
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as? String ?? ""
        self.owner = anyObject["owner"] as? String ?? ""
        self.name = anyObject["name"] as? String ?? ""
        self.icon = anyObject["icon"] as? String ?? ""
        self.nickname = anyObject["nickname"] as? String ?? ""
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "owner": owner,
            "name": name,
            "icon": icon,
            "nickname": nickname,
        ]
    }
}