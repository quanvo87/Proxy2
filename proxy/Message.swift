//
//  Message.swift
//  proxy
//
//  Created by Quan Vo on 8/15/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import UIKit

class Message: NSObject {

    var id: String?
    var text: String?
    var sender: String?
    var receiver: String?
    var timeCreated: NSDate?
    var metadata: KCSMetadata?
    
    init(text: String, receiver: String) {
        super.init()
        self.id = ""
        self.text = text
        self.sender = ""
        self.receiver = receiver
        self.timeCreated = nil
        self.metadata = nil
    }
    
    override func hostToKinveyPropertyMapping() -> [NSObject : AnyObject]! {
        return [
            "id" : KCSEntityKeyId,
            "text" : "text",
            "sender" : "sender",
            "receiver" : "receiver",
            "timeCreated" : "timeCreated",
            "metadata" : KCSEntityKeyMetadata
        ]
    }
}
