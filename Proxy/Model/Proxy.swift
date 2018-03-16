import FirebaseDatabase
import UIKit

enum SettableProxyProperty {
    case hasUnreadMessage(Bool)
    case icon(String)
    case lastMessage(String)
    case nickname(String)
    case timestamp(Double)

    var properties: (name: String, value: Any) {
        switch self {
        case .hasUnreadMessage(let value):
            return ("hasUnreadMessage", value)
        case .icon(let value):
            return ("icon", value)
        case .lastMessage(let value):
            return ("lastMessage", value)
        case .nickname(let value):
            return ("nickname", value)
        case .timestamp(let value):
            return ("timestamp", value)
        }
    }
}

struct Proxy {
    let dateCreated: Double
    let hasUnreadMessage: Bool
    let icon: String
    let key: String
    let lastMessage: String
    let name: String
    let nickname: String
    let ownerId: String
    let timestamp: Double

    var label: NSAttributedString {
        let attributedName = NSMutableAttributedString(string: name)
        if nickname != "" {
            let attributedNickname = NSMutableAttributedString(
                string: " (\(nickname))",
                attributes: [NSAttributedStringKey.font: UIFont.italicSystemFont(ofSize: UIFont.systemFontSize)]
            )
            attributedName.append(attributedNickname)
        }
        return attributedName
    }

    init(dateCreated: Double = Date().timeIntervalSince1970,
         hasUnreadMessage: Bool = false,
         icon: String,
         lastMessage: String = "",
         name: String,
         nickname: String = "",
         ownerId: String,
         timestamp: Double = Date().timeIntervalSince1970) {
        self.dateCreated = dateCreated
        self.hasUnreadMessage = hasUnreadMessage
        self.icon = icon
        self.key = name.lowercased()
        self.lastMessage = lastMessage
        self.name = name
        self.nickname = nickname
        self.ownerId = ownerId
        self.timestamp = timestamp
    }

    init(_ data: DataSnapshot) throws {
        let dictionary = data.value as AnyObject
        guard let dateCreated = dictionary["dateCreated"] as? Double,
            let hasUnreadMessage = dictionary["hasUnreadMessage"] as? Bool,
            let icon = dictionary["icon"] as? String,
            let key = dictionary["key"] as? String,
            let lastMessage = dictionary["lastMessage"] as? String,
            let name = dictionary["name"] as? String,
            let nickname = dictionary["nickname"] as? String,
            let ownerId = dictionary["ownerId"] as? String,
            let timestamp = dictionary["timestamp"] as? Double else {
                throw ProxyError.unknown
        }
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
    static func == (_ lhs: Proxy, _ rhs: Proxy) -> Bool {
        return lhs.dateCreated.isWithinRangeOf(rhs.dateCreated) &&
            lhs.hasUnreadMessage == rhs.hasUnreadMessage &&
            lhs.icon == rhs.icon &&
            lhs.key == rhs.key &&
            lhs.lastMessage == rhs.lastMessage &&
            lhs.name == rhs.name &&
            lhs.nickname == rhs.nickname &&
            lhs.ownerId == rhs.ownerId &&
            lhs.timestamp.isWithinRangeOf(rhs.timestamp)
    }
}
