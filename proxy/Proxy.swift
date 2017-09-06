import FirebaseDatabase

struct Proxy {
    var convoCount = 0
    var dateCreated = Date().timeIntervalSince1970
    var hasUnreadMessage = false
    var icon = ""
    var key = ""
    var lastMessage = ""
    var name = ""
    var nickname = ""
    var ownerId = ""
    var timestamp = Date().timeIntervalSince1970

    init() {}

    // TODO: - remove
    init(name: String, ownerId: String) {
        self.key = name.lowercased()
        self.name = name
        self.ownerId = ownerId
    }

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
            let convoCount = dictionary["convoCount"] as? Int,
            let dateCreated = dictionary["dateCreated"] as? Double,
            let hasUnreadMessage = dictionary["hasUnreadMessage"] as? Bool,
            let icon = dictionary["icon"] as? String,
            let key = dictionary["key"] as? String,
            let lastMessage = dictionary["lastMessage"] as? String,
            let name = dictionary["name"] as? String,
            let nickname = dictionary["nickname"] as? String,
            let ownerId = dictionary["ownerId"] as? String,
            let timestamp = dictionary["timestamp"] as? Double else {
                return nil
        }
        self.convoCount = convoCount
        self.dateCreated = dateCreated
        self.hasUnreadMessage = hasUnreadMessage
        self.icon = icon
        self.key = key
        self.lastMessage = lastMessage
        self.name = name
        self.nickname = nickname
        self.ownerId = ownerId
        self.timestamp = timestamp
    }

    func toDictionary() -> Any {
        return [
            "convoCount": convoCount,
            "dateCreated": dateCreated,
            "hasUnreadMessage": hasUnreadMessage,
            "icon": icon,
            "key": key,
            "lastMessage": lastMessage,
            "name": name,
            "nickname": nickname,
            "ownerId": ownerId,
            "timestamp": timestamp
        ]
    }
}

extension Proxy: Equatable {
    static func ==(_ lhs: Proxy, _ rhs: Proxy) -> Bool {
        return
            lhs.convoCount == rhs.convoCount &&
            lhs.dateCreated.rounded() == rhs.dateCreated.rounded() &&
            lhs.hasUnreadMessage == rhs.hasUnreadMessage &&
            lhs.icon == rhs.icon &&
            lhs.key == rhs.key &&
            lhs.lastMessage == rhs.lastMessage &&
            lhs.name == rhs.name &&
            lhs.nickname == rhs.nickname &&
            lhs.ownerId == rhs.ownerId &&
            lhs.timestamp.rounded() == rhs.timestamp.rounded()
    }
}

enum IncrementableProxyProperty: String {
    case convoCount
}

enum SettableProxyProperty {
    case convoCount(Int)
    case hasUnreadMessage(Bool)
    case icon(String)
    case lastMessage(String)
    case nickname(String)
    case timestamp(Double)

    var properties: (name: String, value: Any) {
        switch self {
        case .convoCount(let value): return ("convoCount", value)
        case .hasUnreadMessage(let value): return ("hasUnreadMessage", value)
        case .icon(let value): return ("icon", value)
        case .lastMessage(let value): return ("lastMessage", value)
        case .nickname(let value): return ("nickname", value)
        case .timestamp(let value): return ("timestamp", value)
        }
    }
}

struct ProxyOwner: Equatable {
    var key = ""
    var ownerId = ""

    init(key: String, ownerId: String) {
        self.key = key
        self.ownerId = ownerId
    }

    init?(_ dictionary: AnyObject) {
        guard
            let key = dictionary["key"] as? String,
            let ownerId = dictionary["ownerId"] as? String else {
                return nil
        }
        self.key = key
        self.ownerId = ownerId
    }

    func toDictionary() -> Any {
        return [
            "key": key,
            "ownerId": ownerId
        ]
    }

    static func ==(_ lhs: ProxyOwner, _ rhs: ProxyOwner) -> Bool {
        return
            lhs.key == rhs.key &&
            lhs.ownerId == rhs.ownerId
    }
}
