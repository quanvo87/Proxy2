//
//  ConvosWith.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct ConvosWith {
    
    var key = ""
    var proxies = ""
    var convo = ""
    
    init() {}
    
    init(key: String, proxies: String, convo: String) {
        self.key = key
        self.proxies = proxies
        self.convo = convo
    }
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as! String
        self.proxies = anyObject["proxies"] as! String
        self.convo = anyObject["convo"] as! String
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "proxies": proxies,
            "convo": convo
        ]
    }
}