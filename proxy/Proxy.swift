//
//  Proxy.swift
//  proxy
//
//  Created by Quan Vo on 8/18/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

struct Proxy {

    var name: String?
    var nickname: String?
    var lastEventMessage = "Just created!"
    var lastEventTime = NSDate()
    var conversationsWith = [String]()
    var invites = [String]()
}

//struct Proxy {
//    
//    let key: String!
//    let name: String!
//    let addedByUser: String!
//    let ref: Firebase?
//    var completed: Bool!
//    
//    // Initialize from arbitrary data
//    init(name: String, addedByUser: String, completed: Bool, key: String = "") {
//        self.key = key
//        self.name = name
//        self.addedByUser = addedByUser
//        self.completed = completed
//        self.ref = nil
//    }
//    
//    init(snapshot: FDataSnapshot) {
//        key = snapshot.key
//        name = snapshot.value["name"] as! String
//        addedByUser = snapshot.value["addedByUser"] as! String
//        completed = snapshot.value["completed"] as! Bool
//        ref = snapshot.ref
//    }
//    
//    func toAnyObject() -> AnyObject {
//        return [
//            "name": name,
//            "addedByUser": addedByUser,
//            "completed": completed
//        ]
//    }
//}