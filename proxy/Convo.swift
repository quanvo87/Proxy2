struct Convo {
    var icon = ""
    var key = ""
    var message = ""
    var receiverDeletedProxy = false
    var receiverId = ""
    var receiverIsBlocked = false
    var receiverLeftConvo = true
    var receiverNickname = ""
    var receiverProxyKey = ""
    var receiverProxyName = ""
    var senderId = ""
    var senderIsBlocked = false
    var senderLeftConvo = true
    var senderNickname = ""
    var senderProxyKey = ""
    var senderProxyName = ""
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
            let receiverIsBlocked = json["receiverIsBlocked"] as? Bool,
            let receiverLeftConvo = json["receiverLeftConvo"] as? Bool,
            let receiverNickname = json["receiverNickname"] as? String,
            let receiverProxyKey = json["receiverProxyKey"] as? String,
            let receiverProxyName = json["receiverProxyName"] as? String,
            let senderId = json["senderId"] as? String,
            let senderIsBlocked = json["senderIsBlocked"] as? Bool,
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
        self.receiverIsBlocked = receiverIsBlocked
        self.receiverLeftConvo = receiverLeftConvo
        self.receiverNickname = receiverNickname
        self.receiverProxyKey = receiverProxyKey
        self.receiverProxyName = receiverProxyName
        self.senderId = senderId
        self.senderIsBlocked = senderIsBlocked
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
            "receiverDeletedProxy": receiverDeletedProxy,
            "receiverId": receiverId,
            "receiverIsBlocked": receiverIsBlocked,
            "receiverLeftConvo": receiverLeftConvo,
            "receiverNickname": receiverNickname,
            "receiverProxyKey": receiverProxyKey,
            "receiverProxyName": receiverProxyName,
            "senderId": senderId,
            "senderIsBlocked": senderIsBlocked,
            "senderLeftConvo": senderLeftConvo,
            "senderNickname": senderNickname,
            "senderProxyKey": senderProxyKey,
            "senderProxyName": senderProxyName,
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
            lhs.receiverDeletedProxy == rhs.receiverDeletedProxy &&
            lhs.receiverId == rhs.receiverId &&
            lhs.receiverIsBlocked == rhs.receiverIsBlocked &&
            lhs.receiverNickname == rhs.receiverNickname &&
            lhs.receiverProxyKey == rhs.receiverProxyKey &&
            lhs.receiverProxyName == rhs.receiverProxyName &&
            lhs.senderId == rhs.senderId &&
            lhs.senderIsBlocked == rhs.senderIsBlocked &&
            lhs.senderLeftConvo == rhs.senderLeftConvo &&
            lhs.senderNickname == rhs.senderNickname &&
            lhs.senderProxyKey == rhs.senderProxyKey &&
            lhs.senderProxyName == rhs.senderProxyName &&
            lhs.timestamp.rounded() == rhs.timestamp.rounded() &&
            lhs.unread == rhs.unread
    }
}
