struct Convo {
    var hasUnreadMessage = false
    var receiverDeletedProxy = false
    var receiverIsBlocked = false
    var receiverLeftConvo = false
    var senderIsBlocked = false
    var senderLeftConvo = false
    var timestamp = 0.0
    var key = ""
    var lastMessage = ""
    var receiverIcon = ""
    var receiverId = ""
    var receiverNickname = ""
    var receiverProxyKey = ""
    var receiverProxyName = ""
    var senderId = ""
    var senderNickname = ""
    var senderProxyKey = ""
    var senderProxyName = ""

    init() {}

    init?(_ dictionary: AnyObject) {
        guard
            let hasUnreadMessage = dictionary["hasUnreadMessage"] as? Bool,
            let receiverDeletedProxy = dictionary["receiverDeletedProxy"] as? Bool,
            let receiverIsBlocked = dictionary["receiverIsBlocked"] as? Bool,
            let receiverLeftConvo = dictionary["receiverLeftConvo"] as? Bool,
            let senderIsBlocked = dictionary["senderIsBlocked"] as? Bool,
            let senderLeftConvo = dictionary["senderLeftConvo"] as? Bool,
            let timestamp = dictionary["timestamp"] as? Double,
            let key = dictionary["key"] as? String,
            let lastMessage = dictionary["lastMessage"] as? String,
            let receiverIcon = dictionary["receiverIcon"] as? String,
            let receiverId = dictionary["receiverId"] as? String,
            let receiverNickname = dictionary["receiverNickname"] as? String,
            let receiverProxyKey = dictionary["receiverProxyKey"] as? String,
            let receiverProxyName = dictionary["receiverProxyName"] as? String,
            let senderId = dictionary["senderId"] as? String,
            let senderNickname = dictionary["senderNickname"] as? String,
            let senderProxyKey = dictionary["senderProxyKey"] as? String,
            let senderProxyName = dictionary["senderProxyName"] as? String else {
                return nil
        }
        self.hasUnreadMessage = hasUnreadMessage
        self.receiverDeletedProxy = receiverDeletedProxy
        self.receiverIsBlocked = receiverIsBlocked
        self.receiverLeftConvo = receiverLeftConvo
        self.senderIsBlocked = senderIsBlocked
        self.senderLeftConvo = senderLeftConvo
        self.timestamp = timestamp
        self.key = key
        self.lastMessage = lastMessage
        self.receiverIcon = receiverIcon
        self.receiverId = receiverId
        self.receiverNickname = receiverNickname
        self.receiverProxyKey = receiverProxyKey
        self.receiverProxyName = receiverProxyName
        self.senderId = senderId
        self.senderNickname = senderNickname
        self.senderProxyKey = senderProxyKey
        self.senderProxyName = senderProxyName
    }

    func toDictionary() -> Any {
        return [
            "hasUnreadMessage": hasUnreadMessage,
            "receiverDeletedProxy": receiverDeletedProxy,
            "receiverIsBlocked": receiverIsBlocked,
            "receiverLeftConvo": receiverLeftConvo,
            "senderIsBlocked": senderIsBlocked,
            "senderLeftConvo": senderLeftConvo,
            "timestamp": timestamp,
            "key": key,
            "lastMessage": lastMessage,
            "receiverIcon": receiverIcon,
            "receiverId": receiverId,
            "receiverNickname": receiverNickname,
            "receiverProxyKey": receiverProxyKey,
            "receiverProxyName": receiverProxyName,
            "senderId": senderId,
            "senderNickname": senderNickname,
            "senderProxyKey": senderProxyKey,
            "senderProxyName": senderProxyName
        ]
    }
}

extension Convo: Equatable {
    static func ==(_ lhs: Convo, _ rhs: Convo) -> Bool {
        return  lhs.hasUnreadMessage == rhs.hasUnreadMessage &&
            lhs.receiverDeletedProxy == rhs.receiverDeletedProxy &&
            lhs.receiverIsBlocked == rhs.receiverIsBlocked &&
            lhs.receiverLeftConvo == lhs.receiverLeftConvo &&
            lhs.senderIsBlocked == rhs.senderIsBlocked &&
            lhs.senderLeftConvo == rhs.senderLeftConvo &&
            lhs.timestamp.rounded() == rhs.timestamp.rounded() &&
            lhs.key == rhs.key &&
            lhs.lastMessage == rhs.lastMessage &&
            lhs.receiverIcon == rhs.receiverIcon &&
            lhs.receiverId == rhs.receiverId &&
            lhs.receiverNickname == rhs.receiverNickname &&
            lhs.receiverProxyKey == rhs.receiverProxyKey &&
            lhs.receiverProxyName == rhs.receiverProxyName &&
            lhs.senderId == rhs.senderId &&
            lhs.senderNickname == rhs.senderNickname &&
            lhs.senderProxyKey == rhs.senderProxyKey &&
            lhs.senderProxyName == rhs.senderProxyName
    }
}

enum SettableConvoProperty {
    case hasUnreadMessage(Bool)
    case receiverDeletedProxy(Bool)
    case receiverIsBlocked(Bool)
    case receiverLeftConvo(Bool)
    case senderIsBlocked(Bool)
    case senderLeftConvo(Bool)
    case timestamp(Double)
    case lastMessage(String)
    case receiverIcon(String)
    case receiverNickname(String)
    case senderNickname(String)


    var properties: (name: String, value: Any) {
        switch self {
        case .hasUnreadMessage(let value): return ("hasUnreadMessage", value)
        case .receiverDeletedProxy(let value): return ("receiverDeletedProxy", value)
        case .receiverIsBlocked(let value): return ("receiverIsBlocked", value)
        case .receiverLeftConvo(let value): return ("receiverLeftConvo", value)
        case .senderIsBlocked(let value): return ("senderIsBlocked", value)
        case .senderLeftConvo(let value): return ("senderLeftConvo", value)
        case .timestamp(let value): return ("timestamp", value)
        case .lastMessage(let value): return ("lastMessage", value)
        case .receiverIcon(let value): return ("receiverIcon", value)
        case .receiverNickname(let value): return ("receiverNickname", value)
        case .senderNickname(let value): return ("senderNickname", value)
        }
    }
}
