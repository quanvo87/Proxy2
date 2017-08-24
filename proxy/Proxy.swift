struct Proxy {
    var convos = 0
    var dateCreated = Date().timeIntervalSince1970
    var icon = ""
    var key = ""
    var lastMessage = ""
    var name = ""
    var nickname = ""
    var ownerId = ""
    var timestamp = Date().timeIntervalSince1970
    var unreadCount = 0

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

    init?(_ dictionary: AnyObject) {
        guard
            let convos = dictionary["convos"] as? Int,
            let dateCreated = dictionary["dateCreated"] as? Double,
            let icon = dictionary["icon"] as? String,
            let key = dictionary["key"] as? String,
            let lastMessage = dictionary["lastMessage"] as? String,
            let name = dictionary["name"] as? String,
            let nickname = dictionary["nickname"] as? String,
            let ownerId = dictionary["ownerId"] as? String,
            let timestamp = dictionary["timestamp"] as? Double,
            let unreadCount = dictionary["unreadCount"] as? Int else {
                return nil
        }
        self.convos = convos
        self.dateCreated = dateCreated
        self.icon = icon
        self.key = key
        self.lastMessage = lastMessage
        self.name = name
        self.nickname = nickname
        self.ownerId = ownerId
        self.timestamp = timestamp
        self.unreadCount = unreadCount
    }

    func toDictionary() -> Any {
        return [
            "convos": convos,
            "dateCreated": dateCreated,
            "icon": icon,
            "key": key,
            "lastMessage": lastMessage,
            "name": name,
            "nickname": nickname,
            "ownerId": ownerId,
            "timestamp": timestamp,
            "unreadCount": unreadCount
        ]
    }
}

extension Proxy: Equatable {
    static func ==(_ lhs: Proxy, _ rhs: Proxy) -> Bool {
        return
            lhs.convos == rhs.convos &&
            lhs.dateCreated.rounded() == rhs.dateCreated.rounded() &&
            lhs.icon == rhs.icon &&
            lhs.key == rhs.key &&
            lhs.lastMessage == rhs.lastMessage &&
            lhs.name == rhs.name &&
            lhs.nickname == rhs.nickname &&
            lhs.ownerId == rhs.ownerId &&
            lhs.timestamp.rounded() == rhs.timestamp.rounded() &&
            lhs.unreadCount == rhs.unreadCount
    }
}

enum IncrementableProxyProperty: String {
    case convos
    case unreadCount
}

enum SettableProxyProperty {
    case convos(Int)
    case dateCreated(Double)
    case icon(String)
    case key(String)
    case lastMessage(String)
    case name(String)
    case nickname(String)
    case ownerId(String)
    case timestamp(Double)
    case unreadCount(Int)

    var properties: (name: String, value: Any) {
        switch self {
        case .convos(let value): return ("convos", value)
        case .dateCreated(let value): return ("dateCreated", value)
        case .icon(let value): return ("icon", value)
        case .key(let value): return ("key", value)
        case .lastMessage(let value): return ("lastMessage", value)
        case .name(let value): return ("name", value)
        case .nickname(let value): return ("nickname", value)
        case .ownerId(let value): return ("ownerId", value)
        case .timestamp(let value): return ("timestamp", value)
        case .unreadCount(let value): return ("unreadCount", value)
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
