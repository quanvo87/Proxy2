struct Convo {
    var icon = ""
    var key = ""
    var message = ""
    var senderId = ""
    var senderIsBlocking = false
    var senderLeftConvo = true
    var senderNickname = ""
    var senderProxyKey = ""
    var senderProxyName = ""
    var receiverDeletedProxy = false
    var receiverId = ""
    var receiverIsBlocking = false
    var receiverLeftConvo = true
    var receiverNickname = ""
    var receiverProxyKey = ""
    var receiverProxyName = ""
    var timestamp = 0.0
    var unread = 0

    init() {}

    init?(_ json: AnyObject) {
        guard
            let icon = json["icon"] as? String,
            let key = json["key"] as? String,
            let message = json["message"] as? String,
            let receiverDeletedProxy = json["receiverDeletedProxy"] as? Bool,
            let receiverId = json["receiverId"] as? String,
            let receiverIsBlocking = json["receiverIsBlocking"] as? Bool,
            let receiverLeftConvo = json["receiverLeftConvo"] as? Bool,
            let receiverNickname = json["receiverNickname"] as? String,
            let receiverProxyKey = json["receiverProxyKey"] as? String,
            let receiverProxyName = json["receiverProxyName"] as? String,
            let senderId = json["senderId"] as? String,
            let senderIsBlocking = json["senderIsBlocking"] as? Bool,
            let senderLeftConvo = json["senderLeftConvo"] as? Bool,
            let senderNickname = json["senderNickname"] as? String,
            let senderProxyKey = json["senderProxyKey"] as? String,
            let senderProxyName = json["senderProxyName"] as? String,
            let timestamp = json["timestamp"] as? Double,
            let unread = json["unread"] as? Int else {
                return nil
        }
        self.icon = icon
        self.key = key
        self.message = message
        self.receiverDeletedProxy = receiverDeletedProxy
        self.receiverId = receiverId
        self.receiverIsBlocking = receiverIsBlocking
        self.receiverLeftConvo = receiverLeftConvo
        self.receiverNickname = receiverNickname
        self.receiverProxyKey = receiverProxyKey
        self.receiverProxyName = receiverProxyName
        self.senderId = senderId
        self.senderIsBlocking = senderIsBlocking
        self.senderLeftConvo = senderLeftConvo
        self.senderNickname = senderNickname
        self.senderProxyKey = senderProxyKey
        self.senderProxyName = senderProxyName
        self.timestamp = timestamp
        self.unread = unread
    }

    func toJSON() -> Any {
        return [
            "icon": icon,
            "key": key,
            "message": message,
            "senderId": senderId,
            "senderIsBlocking": senderIsBlocking,
            "senderLeftConvo": senderLeftConvo,
            "senderNickname": senderNickname,
            "senderProxyKey": senderProxyKey,
            "senderProxyName": senderProxyName,
            "receiverDeletedProxy": receiverDeletedProxy,
            "receiverId": receiverId,
            "receiverIsBlocking": receiverIsBlocking,
            "receiverLeftConvo": receiverLeftConvo,
            "receiverNickname": receiverNickname,
            "receiverProxyKey": receiverProxyKey,
            "receiverProxyName": receiverProxyName,
            "timestamp": timestamp,
            "unread": unread
        ]
    }
}

extension Convo: Equatable {
    static func ==(_ lhs: Convo, _ rhs: Convo) -> Bool {
        return
            lhs.icon == rhs.icon &&
            lhs.key == rhs.key &&
            lhs.message == rhs.message &&
            lhs.senderId == rhs.senderId &&
            lhs.senderIsBlocking == rhs.senderIsBlocking &&
            lhs.senderLeftConvo == rhs.senderLeftConvo &&
            lhs.senderNickname == rhs.senderNickname &&
            lhs.senderProxyKey == rhs.senderProxyKey &&
            lhs.senderProxyName == rhs.senderProxyName &&
            lhs.receiverDeletedProxy == rhs.receiverDeletedProxy &&
            lhs.receiverId == rhs.receiverId &&
            lhs.receiverNickname == rhs.receiverNickname &&
            lhs.receiverProxyKey == rhs.receiverProxyKey &&
            lhs.receiverProxyName == rhs.receiverProxyName &&
            lhs.timestamp.rounded() == rhs.timestamp.rounded() &&
            lhs.unread == rhs.unread
    }
}
