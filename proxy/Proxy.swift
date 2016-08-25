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
    var lastEvent = "Just created!"
    var lastEventTime = NSDate().timeIntervalSince1970
    var conversations = ""
    var invites = ""
    
    init(key: String, name: String) {
        self.key = key
        self.name = name
    }
    
//    init(snapshot: FIRDataSnapshot) {
//        key = snapshot.key
//        name = snapshot.value!["name"] as! String
//        addedByUser = snapshot.value!["addedByUser"] as! String
//        completed = snapshot.value!["completed"] as! Bool
//
//    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "owner": owner!,
            "name": name,
            "nickname": nickname,
            "lastEvent": lastEvent,
            "lastEventTime": lastEventTime,
            "conversations": conversations,
            "invites": invites
        ]
    }
}