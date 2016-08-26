//
//  Invite.swift
//  proxy
//
//  Created by Quan Vo on 8/25/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import FirebaseAuth

struct Invite {
    
    var key = ""
    var senderId = FIRAuth.auth()!.currentUser!.uid
    var senderProxyName = ""
    var receiverId = ""
    var receiverProxyName = ""
    var lastEventTime = 0 - NSDate().timeIntervalSince1970
    var status = "pending"
    var message = ""
    
    init(key: String, senderProxyName: String, receiverId: String, receiverProxyName: String, message: String) {
        self.key = key
        self.senderProxyName = senderProxyName
        self.receiverId = receiverId
        self.receiverProxyName = receiverProxyName
        self.message = message
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "senderId": senderId,
            "senderProxyName": senderProxyName,
            "receiverId": receiverId,
            "receiverProxyName": receiverProxyName,
            "lastEventTime": lastEventTime,
            "status": status,
            "message": message
        ]
    }
}