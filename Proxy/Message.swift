import JSQMessagesViewController

class Message: JSQMessage {
    var dateRead = 0.0
    var key = ""
    var mediaType = ""  // TODO: make enum?
    var mediaURL = ""
    var parentConvo = ""
    var read = false
    var receiverId = ""
    var receiverProxyKey = ""

    init(dateCreated: Double, dateRead: Double, key: String, mediaType: String, parentConvo: String, read: Bool, receiverId: String, receiverProxyKey: String, senderId: String, text: String) {
        self.dateRead = dateRead
        self.key = key
        self.mediaType = mediaType
        self.parentConvo = parentConvo
        self.read = read
        self.receiverId = receiverId
        self.receiverProxyKey = receiverProxyKey
        super.init(senderId: senderId, senderDisplayName: "", date: Date(timeIntervalSince1970: dateCreated), text: text)
    }
    
    init(dateCreated: Double, dateRead: Double, key: String, mediaData: JSQMessageMediaData, mediaType: String, mediaURL: String, parentConvo: String, read: Bool, receiverId: String, receiverProxyKey: String, senderId: String, text: String) {
        self.dateRead = dateRead
        self.key = key
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.parentConvo = parentConvo
        self.read = read
        self.receiverId = receiverId
        self.receiverProxyKey = receiverProxyKey
        super.init(senderId: senderId, senderDisplayName: "", date: Date(timeIntervalSince1970: dateCreated), media: mediaData)
    }
    
    init?(_ dictionary: AnyObject) {
        guard
            let dateCreated = dictionary["dateCreated"] as? Double,
            let dateRead = dictionary["dateRead"] as? Double,
            let key = dictionary["key"] as? String,
            let mediaType = dictionary["mediaType"] as? String,
            let mediaURL = dictionary["mediaURL"] as? String,
            let parentConvo = dictionary["parentConvo"] as? String,
            let read = dictionary["read"] as? Bool,
            let receiverId = dictionary["receiverId"] as? String,
            let receiverProxyKey = dictionary["receiverProxyKey"] as? String,
            let senderDisplayName = dictionary["senderDisplayName"] as? String,
            let senderId = dictionary["senderId"] as? String,
            let text = dictionary["text"] as? String else {
                return nil
        }
        self.dateRead = dateRead
        self.key = key
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.parentConvo = parentConvo
        self.read = read
        self.receiverId = receiverId
        self.receiverProxyKey = receiverProxyKey
        super.init(senderId: senderId, senderDisplayName: senderDisplayName, date: Date(timeIntervalSince1970: dateCreated), text: text)
    }
    
    init?(dictionary: AnyObject, media: JSQMessageMediaData) {
        guard
            let dateCreated = dictionary["dateCreated"] as? Double,
            let dateRead = dictionary["dateRead"] as? Double,
            let key = dictionary["key"] as? String,
            let mediaType = dictionary["mediaType"] as? String,
            let mediaURL = dictionary["mediaURL"] as? String,
            let parentConvo = dictionary["parentConvo"] as? String,
            let read = dictionary["read"] as? Bool,
            let receiverId = dictionary["receiverId"] as? String,
            let receiverProxyKey = dictionary["receiverProxyKey"] as? String,
            let senderDisplayName = dictionary["senderDisplayName"] as? String,
            let senderId = dictionary["senderId"] as? String else {
                return nil
        }
        self.dateRead = dateRead
        self.key = key
        self.mediaType = mediaType
        self.mediaURL = mediaURL
        self.parentConvo = parentConvo
        self.read = read
        self.receiverId = receiverId
        self.receiverProxyKey = receiverProxyKey
        super.init(senderId: senderId, senderDisplayName: senderDisplayName, date: Date(timeIntervalSince1970: dateCreated), media: media)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func toDictionary() -> Any {
        return [
            "dateCreated": date.timeIntervalSince1970,
            "dateRead": dateRead,
            "key": key,
            "mediaType": mediaType,
            "mediaURL": mediaURL,
            "parentConvo": parentConvo,
            "read": read,
            "receiverId": receiverId,
            "receiverProxyKey": receiverProxyKey,
            "senderDisplayName": senderDisplayName,
            "senderId": senderId,
            "text": text
        ]
    }
}

enum SettableMessageProperty {
    case dateRead(Double)
    case mediaType(String)
    case mediaURL(String)
    case read(Bool)

    var properties: (name: String, value: Any) {
        switch self {
        case .dateRead(let value): return ("dateRead", value)
        case .mediaType(let value): return ("mediaType", value)
        case .mediaURL(let value): return ("mediaURL", value)
        case .read(let value): return ("read", value)
        }
    }
}
