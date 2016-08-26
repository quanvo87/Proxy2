////
////  Proxy.swift
////  proxy
////
////  Created by Quan Vo on 8/18/16.
////  Copyright © 2016 Quan Vo. All rights reserved.
////
//
//import FirebaseAuth
//import FirebaseDatabase
//
//struct Proxy {
//    
//    var key = ""
//    var owner = FIRAuth.auth()!.currentUser!.uid
//    var name = ""
//    var nickname = ""
//    var lastEvent = ""
//    var lastEventTime = 0 - NSDate().timeIntervalSince1970
//    var unreadEvents = 0
//    var conversations: [[String: Bool]]
//    var invites = [["": true]]
//    var invitesFrom = [["": true]]
//    
//    init() {}
//    
//    init(key: String, name: String) {
//        self.key = key
//        self.name = name
//        self.lastEvent = "Created at \(NSDate(timeIntervalSince1970: lastEventTime * -1))."
//    }
//    
//    init(snapshot: FIRDataSnapshot) {
//        key = snapshot.key
//        owner = snapshot.value!["owner"] as! String
//        name = snapshot.value!["name"] as! String
//        nickname = snapshot.value!["nickname"] as! String
//        lastEvent = snapshot.value!["lastEvent"] as! String
//        lastEventTime = snapshot.value!["lastEventTime"] as! NSTimeInterval
//        unreadEvents = snapshot.value!["unreadEvents"] as! Int
//        conversations = snapshot.value!["conversations"] as! [[String: Bool]]
//        invites = snapshot.value!["invites"] as! [[String: Bool]]
//        invitesFrom = snapshot.value!["invitesFrom"] as! [[String: Bool]]
//    }
//    
//    func toAnyObject() -> AnyObject {
//        return [
//            "key": key,
//            "owner": owner,
//            "name": name,
//            "nickname": nickname,
//            "lastEvent": lastEvent,
//            "lastEventTime": lastEventTime,
//            "unreadEvents": unreadEvents,
//            "conversations": conversations,
//            "invites": invites,
//            "invitesFrom": invitesFrom
//        ]
//    }
//}