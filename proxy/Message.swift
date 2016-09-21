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
    var mediaType = ""
    var mediaURL = ""
    var read = false
    var timeRead = 0.0
    
    init(key: String, convo: String, mediaType: String, read: Bool, timeRead: Double, senderId: String, date: Double, text: String) {
        self.key = key
        self.convo = convo
        self.mediaType = mediaType
        self.read = read
        self.timeRead = timeRead
        super.init(senderId: senderId, senderDisplayName: "", date: NSDate(timeIntervalSince1970: date), text: text)
    }
    
    init(key: String, convo: String, mediaType: String, mediaURL: String, read: Bool, timeRead: Double, senderId: String, date: Double, text: String, media: JSQMessageMediaData) {
        self.key = key
        self.convo = convo
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.read = read
        self.timeRead = timeRead
        super.init(senderId: senderId, senderDisplayName: "", date: NSDate(timeIntervalSince1970: date), media: media)
    }
    
    init(anyObject: AnyObject) {
        self.key = anyObject["key"] as? String ?? ""
        self.convo = anyObject["convo"] as? String ?? ""
        self.mediaType = anyObject["mediaType"] as? String ?? ""
        self.mediaURL = anyObject["mediaURL"] as? String ?? ""
        self.read = anyObject["read"] as? Bool ?? false
        self.timeRead = anyObject["timeRead"] as? Double ?? 0.0
        super.init(senderId: anyObject["senderId"] as? String ?? "", senderDisplayName: anyObject["senderDisplayName"] as? String ?? "", date: NSDate(timeIntervalSince1970: anyObject["date"] as? Double ?? 0.0), text: anyObject["text"] as? String ?? "")
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toAnyObject() -> AnyObject {
        return [
            "key": key,
            "convo": convo,
            "mediaType": mediaType,
            "mediaURL": mediaURL,
            "read": read,
            "timeRead": timeRead,
            "senderId": senderId,
            "senderDisplayName": senderDisplayName,
            "date": date.timeIntervalSince1970,
            "text": text
        ]
    }
}
