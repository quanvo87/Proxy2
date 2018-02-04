import FirebaseDatabase

// todo: order
struct Convo {
    let hasUnreadMessage: Bool
    let receiverDeletedProxy: Bool
    let timestamp: Double
    let key: String
    let lastMessage: String
    let receiverIcon: String
    let receiverId: String
    let receiverNickname: String
    let receiverProxyKey: String
    let receiverProxyName: String
    let senderIcon: String
    let senderId: String
    let senderNickname: String
    let senderProxyKey: String
    let senderProxyName: String

    var senderDisplayName: String {
        return senderNickname != "" ? senderNickname : senderProxyName
    }

    var receiverDisplayName: String {
        return receiverNickname != "" ? receiverNickname : receiverProxyName
    }

    init(hasUnreadMessage: Bool = false,
         receiverDeletedProxy: Bool = false,
         timestamp: Double = Date().timeIntervalSince1970,
         key: String,
         lastMessage: String = "",
         receiverIcon: String = "",
         receiverId: String,
         receiverNickname: String = "",
         receiverProxyKey: String,
         receiverProxyName: String,
         senderIcon: String,
         senderId: String,
         senderNickname: String = "",
         senderProxyKey: String,
         senderProxyName: String) {
        self.hasUnreadMessage = hasUnreadMessage
        self.receiverDeletedProxy = receiverDeletedProxy
        self.timestamp = timestamp
        self.key = key
        self.lastMessage = lastMessage
        self.receiverIcon = receiverIcon
        self.receiverId = receiverId
        self.receiverNickname = receiverNickname
        self.receiverProxyKey = receiverProxyKey
        self.receiverProxyName = receiverProxyName
        self.senderIcon = senderIcon
        self.senderId = senderId
        self.senderNickname = senderNickname
        self.senderProxyKey = senderProxyKey
        self.senderProxyName = senderProxyName
    }

    init(_ data: DataSnapshot) throws {
        let dictionary = data.value as AnyObject
        guard
            let hasUnreadMessage = dictionary["hasUnreadMessage"] as? Bool,
            let receiverDeletedProxy = dictionary["receiverDeletedProxy"] as? Bool,
            let timestamp = dictionary["timestamp"] as? Double,
            let key = dictionary["key"] as? String,
            let lastMessage = dictionary["lastMessage"] as? String,
            let receiverIcon = dictionary["receiverIcon"] as? String,
            let receiverId = dictionary["receiverId"] as? String,
            let receiverNickname = dictionary["receiverNickname"] as? String,
            let receiverProxyKey = dictionary["receiverProxyKey"] as? String,
            let receiverProxyName = dictionary["receiverProxyName"] as? String,
            let senderIcon = dictionary["senderIcon"] as? String,
            let senderId = dictionary["senderId"] as? String,
            let senderNickname = dictionary["senderNickname"] as? String,
            let senderProxyKey = dictionary["senderProxyKey"] as? String,
            let senderProxyName = dictionary["senderProxyName"] as? String else {
                throw ProxyError.invalidData
        }
        self.hasUnreadMessage = hasUnreadMessage
        self.receiverDeletedProxy = receiverDeletedProxy
        self.timestamp = timestamp
        self.key = key
        self.lastMessage = lastMessage
        self.receiverIcon = receiverIcon
        self.receiverId = receiverId
        self.receiverNickname = receiverNickname
        self.receiverProxyKey = receiverProxyKey
        self.receiverProxyName = receiverProxyName
        self.senderIcon = senderIcon
        self.senderId = senderId
        self.senderNickname = senderNickname
        self.senderProxyKey = senderProxyKey
        self.senderProxyName = senderProxyName
    }

    func toDictionary() -> Any {
        return [
            "hasUnreadMessage": hasUnreadMessage,
            "receiverDeletedProxy": receiverDeletedProxy,
            "timestamp": timestamp,
            "key": key,
            "lastMessage": lastMessage,
            "receiverIcon": receiverIcon,
            "receiverId": receiverId,
            "receiverNickname": receiverNickname,
            "receiverProxyKey": receiverProxyKey,
            "receiverProxyName": receiverProxyName,
            "senderIcon": senderIcon,
            "senderId": senderId,
            "senderNickname": senderNickname,
            "senderProxyKey": senderProxyKey,
            "senderProxyName": senderProxyName
        ]
    }
}

extension Convo: Equatable {
    static func == (_ lhs: Convo, _ rhs: Convo) -> Bool {
        return lhs.hasUnreadMessage == rhs.hasUnreadMessage &&
            lhs.receiverDeletedProxy == rhs.receiverDeletedProxy &&
            lhs.timestamp.isWithinRangeOf(rhs.timestamp) &&
            lhs.key == rhs.key &&
            lhs.lastMessage == rhs.lastMessage &&
            lhs.receiverIcon == rhs.receiverIcon &&
            lhs.receiverId == rhs.receiverId &&
            lhs.receiverNickname == rhs.receiverNickname &&
            lhs.receiverProxyKey == rhs.receiverProxyKey &&
            lhs.receiverProxyName == rhs.receiverProxyName &&
            lhs.senderIcon == rhs.senderIcon &&
            lhs.senderId == rhs.senderId &&
            lhs.senderNickname == rhs.senderNickname &&
            lhs.senderProxyKey == rhs.senderProxyKey &&
            lhs.senderProxyName == rhs.senderProxyName
    }
}

enum SettableConvoProperty {
    case hasUnreadMessage(Bool)
    case receiverDeletedProxy(Bool)
    case timestamp(Double)
    case lastMessage(String)
    case receiverIcon(String)
    case receiverNickname(String)
    case senderIcon(String)
    case senderNickname(String)

    var properties: (name: String, value: Any) {
        switch self {
        case .hasUnreadMessage(let value):
            return ("hasUnreadMessage", value)
        case .receiverDeletedProxy(let value):
            return ("receiverDeletedProxy", value)
        case .timestamp(let value):
            return ("timestamp", value)
        case .lastMessage(let value):
            return ("lastMessage", value)
        case .receiverIcon(let value):
            return ("receiverIcon", value)
        case .receiverNickname(let value):
            return ("receiverNickname", value)
        case .senderIcon(let value):
            return ("senderIcon", value)
        case .senderNickname(let value):
            return ("senderNickname", value)
        }
    }
}
