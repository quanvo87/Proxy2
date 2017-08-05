struct ProxyOwner: Equatable {
    var key = ""
    var ownerId = ""

    init(key: String, ownerId: String) {
        self.key = key
        self.ownerId = ownerId
    }

    init?(_ json: AnyObject) {
        guard
            let key = json["key"] as? String,
            let ownerId = json["ownerId"] as? String else {
                return nil
        }
        self.key = key
        self.ownerId = ownerId
    }

    func toJSON() -> Any {
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

struct Proxy {
    var convos = 0
    var created = Date().timeIntervalSince1970
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

    init?(_ json: AnyObject) {
        guard
            let convos = json["convos"] as? Int,
            let created = json["created"] as? Double,
            let icon = json["icon"] as? String,
            let key = json["key"] as? String,
            let message = json["message"] as? String,
            let name = json["name"] as? String,
            let nickname = json["nickname"] as? String,
            let ownerId = json["ownerId"] as? String,
            let timestamp = json["timestamp"] as? Double,
            let unread = json["unread"] as? Int else {
                return nil
        }
        self.convos = convos
        self.created = created
        self.icon = icon
        self.key = key
        self.message = message
        self.name = name
        self.nickname = nickname
        self.ownerId = ownerId
        self.timestamp = timestamp
        self.unread = unread
    }

    func toJSON() -> Any {
        return [
            "convos": convos,
            "created": created,
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
            lhs.created.rounded() == rhs.created.rounded() &&
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
