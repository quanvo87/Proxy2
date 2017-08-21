struct Convo {
    var icon = ""
    var key = ""
    var message = ""
    var receiverDeletedProxy = false
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
    var unread = 0

    init() {}

    init?(_ dictionary: AnyObject) {
        guard
            let icon = dictionary["icon"] as? String,
            let key = dictionary["key"] as? String,
            let message = dictionary["message"] as? String,
            let receiverDeletedProxy = dictionary["receiverDeletedProxy"] as? Bool,
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
            let timestamp = dictionary["timestamp"] as? Double,
            let unread = dictionary["unread"] as? Int else {
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

enum SettableConvoProperty {
    case icon(String)
    case key(String)
    case message(String)
    case receiverDeletedProxy(Bool)
    case receiverId(String)
    case receiverIsBlocked(Bool)
    case receiverLeftConvo(Bool)
    case receiverNickname(String)
    case receiverProxyKey(String)
    case receiverProxyName(String)
    case senderId(String)
    case senderIsBlocked(Bool)
    case senderLeftConvo(Bool)
    case senderNickname(String)
    case senderProxyKey(String)
    case senderProxyName(String)
    case timestamp(Double)
    case unread(Int)

    var properties: (name: String, newValue: Any) {
        switch self {
        case .icon(let newValue): return ("icon", newValue)
        case .key(let newValue): return ("key", newValue)
        case .message(let newValue): return ("message", newValue)
        case .receiverDeletedProxy(let newValue): return ("receiverDeletedProxy", newValue)
        case .receiverId(let newValue): return ("receiverId", newValue)
        case .receiverIsBlocked(let newValue): return ("receiverIsBlocked", newValue)
        case .receiverLeftConvo(let newValue): return ("receiverLeftConvo", newValue)
        case .receiverNickname(let newValue): return ("receiverNickname", newValue)
        case .receiverProxyKey(let newValue): return ("receiverProxyKey", newValue)
        case .receiverProxyName(let newValue): return ("receiverProxyName", newValue)
        case .senderId(let newValue): return ("senderId", newValue)
        case .senderIsBlocked(let newValue): return ("senderIsBlocked", newValue)
        case .senderLeftConvo(let newValue): return ("senderLeftConvo", newValue)
        case .senderNickname(let newValue): return ("senderNickname", newValue)
        case .senderProxyKey(let newValue): return ("senderProxyKey", newValue)
        case .senderProxyName(let newValue): return ("senderProxyName", newValue)
        case .timestamp(let newValue): return ("timestamp", newValue)
        case .unread(let newValue): return ("unread", newValue)
        }
    }
}

enum IncrementableConvoProperty: String {
    case unread
}
