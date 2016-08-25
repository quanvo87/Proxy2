//
//  Proxy.swift
//  proxy
//
//  Created by Quan Vo on 8/18/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth
import FirebaseDatabase

struct Proxy {
    
    var key = ""
    var owner = FIRAuth.auth()?.currentUser?.uid
    var name = ""
    var nickname = ""
    var lastEvent = "Just created."
    var lastEventTime = 0 - NSDate().timeIntervalSince1970
    var unreadEvents = 0
    var conversations = ""
    var invites = ""
    
    init(key: String, name: String) {
        self.key = key
        self.name = name
    }
    
    init(snapshot: FIRDataSnapshot) {
        key = snapshot.key
        name = snapshot.value!["name"] as! String
        nickname = snapshot.value!["nickname"] as! String
        lastEvent = snapshot.value!["lastEvent"] as! String
        lastEventTime = snapshot.value!["lastEventTime"] as! NSTimeInterval
        unreadEvents = snapshot.value!["unreadEvents"] as! Int
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "owner": owner!,
            "name": name,
            "nickname": nickname,
            "lastEvent": lastEvent,
            "lastEventTime": lastEventTime,
            "unreadEvents": unreadEvents,
            "conversations": conversations,
            "invites": invites
        ]
    }
}