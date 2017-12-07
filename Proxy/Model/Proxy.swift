import FirebaseDatabase

struct Proxy {
    var hasUnreadMessage = false
    var dateCreated = Date().timeIntervalSince1970
    var timestamp = Date().timeIntervalSince1970
    var convoCount = 0
    var icon = ""
    var key = ""
    var lastMessage = ""
    var name = ""
    var nickname = ""
    var ownerId = ""

    init() {}

    init(icon: String, name: String, ownerId: String) {
        self.icon = icon
        self.key = name.lowercased()
        self.name = name
        self.ownerId = ownerId
    }

    init?(_ data: DataSnapshot) {
        self.init(data.value as AnyObject)
    }

    init?(_ dictionary: AnyObject) {
        guard
            let hasUnreadMessage = dictionary["hasUnreadMessage"] as? Bool,
            let dateCreated = dictionary["dateCreated"] as? Double,
            let timestamp = dictionary["timestamp"] as? Double,
            let convoCount = dictionary["convoCount"] as? Int,
            let icon = dictionary["icon"] as? String,
            let key = dictionary["key"] as? String,
            let lastMessage = dictionary["lastMessage"] as? String,
            let name = dictionary["name"] as? String,
            let nickname = dictionary["nickname"] as? String,
            let ownerId = dictionary["ownerId"] as? String else {
                return nil
        }
        self.hasUnreadMessage = hasUnreadMessage
        self.dateCreated = dateCreated
        self.timestamp = timestamp
        self.convoCount = convoCount
        self.icon = icon
        self.key = key
        self.lastMessage = lastMessage
        self.name = name
        self.nickname = nickname
        self.ownerId = ownerId
    }

    func toDictionary() -> Any {
        return [
            "hasUnreadMessage": hasUnreadMessage,
            "dateCreated": dateCreated,
            "timestamp": timestamp,
            "convoCount": convoCount,
            "icon": icon,
            "key": key,
            "lastMessage": lastMessage,
            "name": name,
            "nickname": nickname,
            "ownerId": ownerId
        ]
    }
}

extension Proxy: Equatable {
    static func ==(_ lhs: Proxy, _ rhs: Proxy) -> Bool {
        return lhs.hasUnreadMessage == rhs.hasUnreadMessage &&
            lhs.dateCreated.rounded() == rhs.dateCreated.rounded() &&
            lhs.timestamp.rounded() == rhs.timestamp.rounded() &&
            lhs.convoCount == rhs.convoCount &&
            lhs.icon == rhs.icon &&
            lhs.key == rhs.key &&
            lhs.lastMessage == rhs.lastMessage &&
            lhs.name == rhs.name &&
            lhs.nickname == rhs.nickname &&
            lhs.ownerId == rhs.ownerId
    }
}

enum IncrementableProxyProperty: String {
    case convoCount
}

enum SettableProxyProperty {
    case hasUnreadMessage(Bool)
    case timestamp(Double)
    case convoCount(Int)
    case icon(String)
    case lastMessage(String)
    case nickname(String)

    var properties: (name: String, value: Any) {
        switch self {
        case .hasUnreadMessage(let value): return ("hasUnreadMessage", value)
        case .timestamp(let value): return ("timestamp", value)
        case .convoCount(let value): return ("convoCount", value)
        case .icon(let value): return ("icon", value)
        case .lastMessage(let value): return ("lastMessage", value)
        case .nickname(let value): return ("nickname", value)
        }
    }
}
