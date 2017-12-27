import FirebaseDatabase

struct Convo {
    let hasUnreadMessage: Bool
    let timestamp: Double
    let key: String
    let lastMessage: String
    let receiverIcon: String
    let receiverId: String
    let receiverNickname: String
    let receiverProxyKey: String
    let receiverProxyName: String
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

    init(key: String,
         receiverId: String,
         receiverProxyKey: String,
         receiverProxyName: String,
         senderId: String,
         senderProxyKey: String,
         senderProxyName: String,
         hasUnreadMessage: Bool = false,
         timestamp: Double = Date().timeIntervalSince1970,
         lastMessage: String = "",
         receiverIcon: String = "",
         receiverNickname: String = "",
         senderNickname: String = "") {
        self.key = key
        self.receiverId = receiverId
        self.receiverProxyKey = receiverProxyKey
        self.receiverProxyName = receiverProxyName
        self.senderId = senderId
        self.senderProxyKey = senderProxyKey
        self.senderProxyName = senderProxyName
        self.hasUnreadMessage = hasUnreadMessage
        self.timestamp = timestamp
        self.lastMessage = lastMessage
        self.receiverIcon = receiverIcon
        self.receiverNickname = receiverNickname
        self.senderNickname = senderNickname
    }

    init?(_ data: DataSnapshot) {
        self.init(data.value as AnyObject)
    }

    init?(_ dictionary: AnyObject) {
        guard
            let hasUnreadMessage = dictionary["hasUnreadMessage"] as? Bool,
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
        return lhs.hasUnreadMessage == rhs.hasUnreadMessage &&
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
    case timestamp(Double)
    case lastMessage(String)
    case receiverIcon(String)
    case receiverNickname(String)
    case senderNickname(String)

    var properties: (name: String, value: Any) {
        switch self {
        case .hasUnreadMessage(let value):
            return ("hasUnreadMessage", value)
        case .timestamp(let value):
            return ("timestamp", value)
        case .lastMessage(let value):
            return ("lastMessage", value)
        case .receiverIcon(let value):
            return ("receiverIcon", value)
        case .receiverNickname(let value):
            return ("receiverNickname", value)
        case .senderNickname(let value):
            return ("senderNickname", value)
        }
    }
}
