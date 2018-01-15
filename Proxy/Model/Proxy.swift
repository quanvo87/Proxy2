import FirebaseDatabase

struct Proxy {
    let hasUnreadMessage: Bool
    let dateCreated: Double
    let timestamp: Double
    let icon: String
    let key: String
    let lastMessage: String
    let name: String
    let nickname: String
    let ownerId: String

    init(hasUnreadMessage: Bool = false,
         dateCreated: Double = Date().timeIntervalSince1970,
         timestamp: Double = Date().timeIntervalSince1970,
         icon: String = ProxyService.makeRandomIconName(),
         lastMessage: String = "",
         name: String,
         nickname: String = "",
         ownerId: String) {
        self.hasUnreadMessage = hasUnreadMessage
        self.dateCreated = dateCreated
        self.timestamp = timestamp
        self.icon = icon
        self.key = name.lowercased()
        self.lastMessage = lastMessage
        self.name = name
        self.nickname = nickname
        self.ownerId = ownerId
    }

    init?(_ data: DataSnapshot) {
        let dictionary = data.value as AnyObject
        guard
            let hasUnreadMessage = dictionary["hasUnreadMessage"] as? Bool,
            let dateCreated = dictionary["dateCreated"] as? Double,
            let timestamp = dictionary["timestamp"] as? Double,
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
    static func == (_ lhs: Proxy, _ rhs: Proxy) -> Bool {
        return lhs.hasUnreadMessage == rhs.hasUnreadMessage &&
            lhs.dateCreated.rounded() == rhs.dateCreated.rounded() &&
            lhs.timestamp.rounded() == rhs.timestamp.rounded() &&
            lhs.icon == rhs.icon &&
            lhs.key == rhs.key &&
            lhs.lastMessage == rhs.lastMessage &&
            lhs.name == rhs.name &&
            lhs.nickname == rhs.nickname &&
            lhs.ownerId == rhs.ownerId
    }
}

enum SettableProxyProperty {
    case hasUnreadMessage(Bool)
    case timestamp(Double)
    case icon(String)
    case lastMessage(String)
    case nickname(String)

    var properties: (name: String, value: Any) {
        switch self {
        case .hasUnreadMessage(let value):
            return ("hasUnreadMessage", value)
        case .timestamp(let value):
            return ("timestamp", value)
        case .icon(let value):
            return ("icon", value)
        case .lastMessage(let value):
            return ("lastMessage", value)
        case .nickname(let value):
            return ("nickname", value)
        }
    }
}
