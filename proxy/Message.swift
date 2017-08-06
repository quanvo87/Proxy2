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
        super.init(senderId: senderId, senderDisplayName: "", date: Date(timeIntervalSince1970: date), text: text)
    }
    
    init(key: String, convo: String, mediaType: String, mediaURL: String, read: Bool, timeRead: Double, senderId: String, date: Double, text: String, media: JSQMessageMediaData) {
        self.key = key
        self.convo = convo
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.read = read
        self.timeRead = timeRead
        super.init(senderId: senderId, senderDisplayName: "", date: Date(timeIntervalSince1970: date), media: media)
    }
    
    init?(anyObject: AnyObject) {
        if
            let key = anyObject["key"] as? String,
            let convo = anyObject["convo"] as? String,
            let mediaType = anyObject["mediaType"] as? String,
            let mediaURL = anyObject["mediaURL"] as? String,
            let read = anyObject["read"] as? Bool,
            let timeRead = anyObject["timeRead"] as? Double,
            let senderId = anyObject["senderId"] as? String,
            let senderDisplayName = anyObject["senderDisplayName"] as? String,
            let date = anyObject["date"] as? Double,
            let text = anyObject["text"] as? String {
            self.key = key
            self.convo = convo
            self.mediaType = mediaType
            self.mediaURL = mediaURL
            self.read = read
            self.timeRead = timeRead
            super.init(senderId: senderId, senderDisplayName: senderDisplayName, date: Date(timeIntervalSince1970: date), text: text)
        } else {
            return nil
        }
    }
    
    init?(anyObject: AnyObject, media: JSQMessageMediaData) {
        if
            let key = anyObject["key"] as? String,
            let convo = anyObject["convo"] as? String,
            let mediaType = anyObject["mediaType"] as? String,
            let mediaURL = anyObject["mediaURL"] as? String,
            let read = anyObject["read"] as? Bool,
            let timeRead = anyObject["timeRead"] as? Double,
            let senderId = anyObject["senderId"] as? String,
            let senderDisplayName = anyObject["senderDisplayName"] as? String,
            let date = anyObject["date"] as? Double {
            self.key = key
            self.convo = convo
            self.mediaType = mediaType
            self.mediaURL = mediaURL
            self.read = read
            self.timeRead = timeRead
            super.init(senderId: senderId, senderDisplayName: senderDisplayName, date: Date(timeIntervalSince1970: date), media: media)
        } else {
            return nil
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toAnyObject() -> Any {
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
