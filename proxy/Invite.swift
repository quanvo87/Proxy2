//
//  Invite.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit

class Invite: NSObject {

    var id: String?
    var sender: String?
    var receiver: String?
    var metadata: KCSMetadata?
    
    init(receiver: String) {
        super.init()
        self.id = ""
        self.sender = ""
        self.receiver = receiver
        self.metadata = nil
    }
    
    override func hostToKinveyPropertyMapping() -> [NSObject : AnyObject]! {
        return [
            "id" : KCSEntityKeyId,
            "sender" : "sender",
            "receiver" : "receiver",
            "metadata" : KCSEntityKeyMetadata
        ]
    }
}