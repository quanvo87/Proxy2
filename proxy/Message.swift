//
//  Message.swift
//  proxy
//
//  Created by Quan Vo on 8/28/16.
//  Copyright © 2016 Quan Vo. All rights reserved.
//

import JSQMessagesViewController

class Message: JSQMessage {
    
    var key = ""
    var convo = ""
    var read = false
    var timeRead = 0.0
    
    init(key: String, convo: String, senderId: String, date: Double, text: String) {
        self.key = key
        self.convo = convo
        super.init(senderId: senderId, senderDisplayName: "", date: NSDate(timeIntervalSince1970: date), text: text)
    }
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as! String
        self.convo = anyObject["convo"] as! String
        self.read = anyObject["read"] as! Bool
        self.timeRead = anyObject["timeRead"] as! Double
        super.init(senderId: anyObject["senderId"] as! String, senderDisplayName: anyObject["senderDisplayName"] as! String, date: NSDate(timeIntervalSince1970:anyObject["date"] as! Double), text: anyObject["text"] as! String)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "convo": convo,
            "read": read,
            "timeRead": timeRead,
            "senderId": senderId,
            "senderDisplayName": senderDisplayName,
            "date": date.timeIntervalSince1970,
            "text": text
        ]
    }
}