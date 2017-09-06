struct Convo {
    var hasUnreadMessage = false
    var key = ""
    var lastMessage = ""
    var receiverDeletedProxy = false
    var receiverIcon = ""
    var receiverId = ""
    var receiverIsBlocked = false
    var receiverLeftConvo = false
    var receiverNickname = ""
    var receiverProxyKey = ""
    var receiverProxyName = ""
    var senderId = ""
    var senderIsBlocked = false
    var senderLeftConvo = false
    var senderNickname = ""
    var senderProxyKey = ""
    var senderProxyName = ""
    var timestamp = 0.0

    init() {}

    init?(_ dictionary: AnyObject) {
        guard
            let hasUnreadMessage = dictionary["hasUnreadMessage"] as? Bool,
            let key = dictionary["key"] as? String,
            let lastMessage = dictionary["lastMessage"] as? String,
            let receiverDeletedProxy = dictionary["receiverDeletedProxy"] as? Bool,
            let receiverIcon = dictionary["receiverIcon"] as? String,
            let receiverId = dictionary["receiverId"] as? String,
            let receiverIsBlocked = dictionary["receiverIsBlocked"] as? Bool,
            let receiverLeftConvo = dictionary["receiverLeftConvo"] as? Bool,
            let receiverNickname = dictionary["receiverNickname"] as? String,
            let receiverProxyKey = dictionary["receiverProxyKey"] as? String,
            let receiverProxyName = dictionary["receiverProxyName"] as? String,
            let senderId = dictionary["senderId"] as? String,
            let senderIsBlocked = dictionary["senderIsBlocked"] as? Bool,
            let senderLeftConvo = dictionary["senderLeftConvo"] as? Bool,
            let senderNickname = dictionary["senderNickname"] as? String,
            let senderProxyKey = dictionary["senderProxyKey"] as? String,
            let senderProxyName = dictionary["senderProxyName"] as? String,
            let timestamp = dictionary["timestamp"] as? Double else {
                return nil
        }
        self.hasUnreadMessage = hasUnreadMessage
        self.key = key
        self.lastMessage = lastMessage
        self.receiverDeletedProxy = receiverDeletedProxy
        self.receiverIcon = receiverIcon
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
    }

    func toDictionary() -> Any {
        return [
            "hasUnreadMessage": hasUnreadMessage,
            "key": key,
            "lastMessage": lastMessage,
            "receiverDeletedProxy": receiverDeletedProxy,
            "receiverIcon": receiverIcon,
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
            "timestamp": timestamp
        ]
    }
}

extension Convo: Equatable {
    static func ==(_ lhs: Convo, _ rhs: Convo) -> Bool {
        return
            lhs.hasUnreadMessage == rhs.hasUnreadMessage &&
            lhs.key == rhs.key &&
            lhs.lastMessage == rhs.lastMessage &&
            lhs.receiverDeletedProxy == rhs.receiverDeletedProxy &&
            lhs.receiverIcon == rhs.receiverIcon &&
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
            lhs.timestamp.rounded() == rhs.timestamp.rounded()
    }
}

enum SettableConvoProperty {
    case hasUnreadMessage(Bool)
    case lastMessage(String)
    case receiverDeletedProxy(Bool)
    case receiverIcon(String)
    case receiverIsBlocked(Bool)
    case receiverLeftConvo(Bool)
    case receiverNickname(String)
    case senderIsBlocked(Bool)
    case senderLeftConvo(Bool)
    case senderNickname(String)
    case timestamp(Double)

    var properties: (name: String, value: Any) {
        switch self {
            case .hasUnreadMessage(let value): return ("hasUnreadMessage", value)
        case .lastMessage(let value): return ("lastMessage", value)
        case .receiverDeletedProxy(let value): return ("receiverDeletedProxy", value)
        case .receiverIcon(let value): return ("receiverIcon", value)
        case .receiverIsBlocked(let value): return ("receiverIsBlocked", value)
        case .receiverLeftConvo(let value): return ("receiverLeftConvo", value)
        case .receiverNickname(let value): return ("receiverNickname", value)
        case .senderIsBlocked(let value): return ("senderIsBlocked", value)
        case .senderLeftConvo(let value): return ("senderLeftConvo", value)
        case .senderNickname(let value): return ("senderNickname", value)
        case .timestamp(let value): return ("timestamp", value)
        }
    }
}
