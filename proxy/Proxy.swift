struct Proxy {
    var convos = 0
    var dateCreated = Date().timeIntervalSince1970
    var icon = ""
    var key = ""
    var message = ""
    var name = ""
    var nickname = ""
    var ownerId = ""
    var timestamp = Date().timeIntervalSince1970
    var unread = 0

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
            let message = dictionary["message"] as? String,
            let name = dictionary["name"] as? String,
            let nickname = dictionary["nickname"] as? String,
            let ownerId = dictionary["ownerId"] as? String,
            let timestamp = dictionary["timestamp"] as? Double,
            let unread = dictionary["unread"] as? Int else {
                return nil
        }
        self.convos = convos
        self.dateCreated = dateCreated
        self.icon = icon
        self.key = key
        self.message = message
        self.name = name
        self.nickname = nickname
        self.ownerId = ownerId
        self.timestamp = timestamp
        self.unread = unread
    }

    func toDictionary() -> Any {
        return [
            "convos": convos,
            "dateCreated": dateCreated,
            "icon": icon,
            "key": key,
            "message": message,
            "name": name,
            "nickname": nickname,
            "ownerId": ownerId,
            "timestamp": timestamp,
            "unread": unread
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
            lhs.message == rhs.message &&
            lhs.name == rhs.name &&
            lhs.nickname == rhs.nickname &&
            lhs.ownerId == rhs.ownerId &&
            lhs.timestamp.rounded() == rhs.timestamp.rounded() &&
            lhs.unread == rhs.unread
    }
}

enum SettableProxyProperty {
    case convos(Int)
    case dateCreated(Double)
    case icon(String)
    case key(String)
    case message(String)
    case name(String)
    case nickname(String)
    case ownerId(String)
    case timestamp(Double)
    case unread(Int)

    var properties: (name: String, newValue: Any) {
        switch self {
        case .convos(let newValue): return ("convos", newValue)
        case .dateCreated(let newValue): return ("dateCreated", newValue)
        case .icon(let newValue): return ("icon", newValue)
        case .key(let newValue): return ("key", newValue)
        case .message(let newValue): return ("message", newValue)
        case .name(let newValue): return ("name", newValue)
        case .nickname(let newValue): return ("nickname", newValue)
        case .ownerId(let newValue): return ("ownerId", newValue)
        case .timestamp(let newValue): return ("timestamp", newValue)
        case .unread(let newValue): return ("unread", newValue)
        }
    }
}

enum IncrementableProxyProperty: String {
    case convos
    case unread
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
