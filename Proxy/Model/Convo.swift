import FirebaseDatabase
import UIKit

enum SettableConvoProperty {
    case hasUnreadMessage(Bool)
    case lastMessage(String)
    case receiverDeletedProxy(Bool)
    case receiverIcon(String)
    case receiverIsBlocked(Bool)
    case receiverIsBlocking(Bool)
    case receiverNickname(String)
    case senderIcon(String)
    case senderNickname(String)
    case timestamp(Double)

    var properties: (name: String, value: Any) {
        switch self {
        case .hasUnreadMessage(let value):
            return ("hasUnreadMessage", value)
        case .lastMessage(let value):
            return ("lastMessage", value)
        case .receiverDeletedProxy(let value):
            return ("receiverDeletedProxy", value)
        case .receiverIcon(let value):
            return ("receiverIcon", value)
        case .receiverIsBlocked(let value):
            return ("receiverIsBlocked", value)
        case .receiverIsBlocking(let value):
            return ("receiverIsBlocking", value)
        case .receiverNickname(let value):
            return ("receiverNickname", value)
        case .senderIcon(let value):
            return ("senderIcon", value)
        case .senderNickname(let value):
            return ("senderNickname", value)
        case .timestamp(let value):
            return ("timestamp", value)
        }
    }
}

struct Convo {
    let hasUnreadMessage: Bool
    let key: String
    let lastMessage: String
    let receiverDeletedProxy: Bool
    let receiverIcon: String
    let receiverId: String
    let receiverIsBlocked: Bool
    let receiverIsBlocking: Bool
    let receiverNickname: String
    let receiverProxyKey: String
    let receiverProxyName: String
    let senderIcon: String
    let senderId: String
    let senderNickname: String
    let senderProxyKey: String
    let senderProxyName: String
    let timestamp: Double

    var asDictionary: Any {
        return [
            "hasUnreadMessage": hasUnreadMessage,
            "key": key,
            "lastMessage": lastMessage,
            "receiverDeletedProxy": receiverDeletedProxy,
            "receiverIcon": receiverIcon,
            "receiverId": receiverId,
            "receiverIsBlocked": receiverIsBlocked,
            "receiverIsBlocking": receiverIsBlocking,
            "receiverNickname": receiverNickname,
            "receiverProxyKey": receiverProxyKey,
            "receiverProxyName": receiverProxyName,
            "senderIcon": senderIcon,
            "senderId": senderId,
            "senderNickname": senderNickname,
            "senderProxyKey": senderProxyKey,
            "senderProxyName": senderProxyName,
            "timestamp": timestamp
        ]
    }

    var label: NSAttributedString {
        let receiver: NSMutableAttributedString
        if receiverDeletedProxy {
            receiver = NSMutableAttributedString(
                string: receiverDisplayName,
                attributes: StringAttributes.redAndStrikethrough
            )
        } else if receiverNickname != "" {
            receiver = NSMutableAttributedString(string: receiverNickname, attributes: StringAttributes.blue)
        } else {
            receiver = NSMutableAttributedString(string: receiverProxyName)
        }
        let sender: NSAttributedString
        if senderNickname != "" {
            sender = NSAttributedString(string: senderNickname, attributes: StringAttributes.blue)
        } else {
            sender = NSAttributedString(string: senderProxyName, attributes: StringAttributes.gray)
        }
        let comma = NSAttributedString(string: ", ", attributes: StringAttributes.gray)
        receiver.append(comma)
        receiver.append(sender)
        return receiver
    }

    var senderDisplayName: String {
        return senderNickname != "" ? senderNickname : senderProxyName
    }

    var receiverDisplayName: String {
        return receiverNickname != "" ? receiverNickname : receiverProxyName
    }

    init(hasUnreadMessage: Bool = false,
         key: String,
         lastMessage: String = "",
         receiverDeletedProxy: Bool = false,
         receiverIcon: String = "",
         receiverId: String,
         receiverIsBlocked: Bool = false,
         receiverIsBlocking: Bool = false,
         receiverNickname: String,
         receiverProxyKey: String,
         receiverProxyName: String,
         senderIcon: String,
         senderId: String,
         senderNickname: String,
         senderProxyKey: String,
         senderProxyName: String,
         timestamp: Double = Date().timeIntervalSince1970) {
        self.hasUnreadMessage = hasUnreadMessage
        self.key = key
        self.lastMessage = lastMessage
        self.receiverDeletedProxy = receiverDeletedProxy
        self.receiverIcon = receiverIcon
        self.receiverId = receiverId
        self.receiverIsBlocked = receiverIsBlocked
        self.receiverIsBlocking = receiverIsBlocking
        self.receiverNickname = receiverNickname
        self.receiverProxyKey = receiverProxyKey
        self.receiverProxyName = receiverProxyName
        self.senderIcon = senderIcon
        self.senderId = senderId
        self.senderNickname = senderNickname
        self.senderProxyKey = senderProxyKey
        self.senderProxyName = senderProxyName
        self.timestamp = timestamp
    }

    init(_ data: DataSnapshot) throws {
        let dictionary = data.value as AnyObject
        guard let hasUnreadMessage = dictionary["hasUnreadMessage"] as? Bool,
            let key = dictionary["key"] as? String,
            let lastMessage = dictionary["lastMessage"] as? String,
            let receiverDeletedProxy = dictionary["receiverDeletedProxy"] as? Bool,
            let receiverIcon = dictionary["receiverIcon"] as? String,
            let receiverId = dictionary["receiverId"] as? String,
            let receiverIsBlocked = dictionary["receiverIsBlocked"] as? Bool,
            let receiverIsBlocking = dictionary["receiverIsBlocking"] as? Bool,
            let receiverNickname = dictionary["receiverNickname"] as? String,
            let receiverProxyKey = dictionary["receiverProxyKey"] as? String,
            let receiverProxyName = dictionary["receiverProxyName"] as? String,
            let senderIcon = dictionary["senderIcon"] as? String,
            let senderId = dictionary["senderId"] as? String,
            let senderNickname = dictionary["senderNickname"] as? String,
            let senderProxyKey = dictionary["senderProxyKey"] as? String,
            let senderProxyName = dictionary["senderProxyName"] as? String,
            let timestamp = dictionary["timestamp"] as? Double else {
                throw ProxyError.unknown
        }
        self.hasUnreadMessage = hasUnreadMessage
        self.key = key
        self.lastMessage = lastMessage
        self.receiverDeletedProxy = receiverDeletedProxy
        self.receiverIcon = receiverIcon
        self.receiverId = receiverId
        self.receiverIsBlocked = receiverIsBlocked
        self.receiverIsBlocking = receiverIsBlocking
        self.receiverNickname = receiverNickname
        self.receiverProxyKey = receiverProxyKey
        self.receiverProxyName = receiverProxyName
        self.senderIcon = senderIcon
        self.senderId = senderId
        self.senderNickname = senderNickname
        self.senderProxyKey = senderProxyKey
        self.senderProxyName = senderProxyName
        self.timestamp = timestamp
    }
}

extension Convo: Equatable {
    static func == (_ lhs: Convo, _ rhs: Convo) -> Bool {
        return lhs.hasUnreadMessage == rhs.hasUnreadMessage &&
            lhs.key == rhs.key &&
            lhs.lastMessage == rhs.lastMessage &&
            lhs.receiverDeletedProxy == rhs.receiverDeletedProxy &&
            lhs.receiverIcon == rhs.receiverIcon &&
            lhs.receiverId == rhs.receiverId &&
            lhs.receiverIsBlocked == rhs.receiverIsBlocked &&
            lhs.receiverIsBlocking == rhs.receiverIsBlocking &&
            lhs.receiverNickname == rhs.receiverNickname &&
            lhs.receiverProxyKey == rhs.receiverProxyKey &&
            lhs.receiverProxyName == rhs.receiverProxyName &&
            lhs.senderIcon == rhs.senderIcon &&
            lhs.senderId == rhs.senderId &&
            lhs.senderNickname == rhs.senderNickname &&
            lhs.senderProxyKey == rhs.senderProxyKey &&
            lhs.senderProxyName == rhs.senderProxyName &&
            lhs.timestamp.isWithinRangeOf(rhs.timestamp)
    }
}
