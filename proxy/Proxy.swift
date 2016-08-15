//
//  Proxy.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import Foundation
import CoreData

class Proxy: NSManagedObject {
    
    override func hostToKinveyPropertyMapping() -> [NSObject : AnyObject]! {
        return [
            "id" : KCSEntityKeyId,
            "owner" : "owner",
            "name" : "name",
            "nickname" : "nickname",
            "lastEventMessage" : "lastEventMessage",
            "lastEventTime" : "lastEventTime",
            "conversationsWith" : "conversationsWith",
            "invites" : "invites",
        ]
    }
}