//
//  Proxy.swift
//  proxy
//
//  Created by Quan Vo on 8/18/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit

class Proxy: NSObject {

    var id = ""
    var owner = KCSUser.activeUser().userId
    var name = ""
    var nickname = ""
    var lastEventMessage = ""
    var lastEventTime = NSDate()
    var conversationsWith = [String]()
    var invites = [String]()
    
    override func hostToKinveyPropertyMapping() -> [NSObject : AnyObject]! {
        return [
            "id" : KCSEntityKeyId,
            "owner" : "owner",
            "name" : "name",
            "nickname" : "nickname",
            "lastEventMessage" : "lastEventMessage",
            "lastEventTime" : "lastEventTime",
            "conversationsWith" : "conversationsWith",
            "invites" : "invites"
        ]
    }
}
