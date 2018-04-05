import FirebaseDatabase
import MessageKit

enum SettableMessageProperty {
    case dateRead(Date)

    var properties: (name: String, value: Any) {
        switch self {
        case .dateRead(let value):
            return ("dateRead", value)
        }
    }
}

struct Message: MessageType {
    let sender: Sender
    let messageId: String
    let sentDate: Date
    let data: MessageData

    let dateRead: Date
    let parentConvoKey: String
    let receiverId: String
    let receiverProxyKey: String
    let senderProxyKey: String

    var asDictionary: Any {
        var text: String
        switch data {
        case .text(let _text):
            text = _text
        default:
            text = ""
        }
        return [
            "senderId": sender.id,
            "senderDisplayName": sender.displayName,
            "messageId": messageId,
            "sentDate": sentDate.timeIntervalSince1970,
            "text": text,
            "dateRead": dateRead.timeIntervalSince1970,
            "parentConvoKey": parentConvoKey,
            "receiverId": receiverId,
            "receiverProxyKey": receiverProxyKey,
            "senderProxyKey": senderProxyKey
        ]
    }

    var hasBeenRead: Bool {
        return dateRead > Date.distantPast
    }

    init(sender: Sender,
         messageId: String,
         data: MessageData,
         dateRead: Date = Date.distantPast,
         parentConvoKey: String,
         receiverId: String,
         receiverProxyKey: String,
         senderProxyKey: String) {
        self.sender = sender
        self.messageId = messageId
        self.sentDate = Date()
        self.data = data
        self.dateRead = dateRead
        self.parentConvoKey = parentConvoKey
        self.receiverId = receiverId
        self.receiverProxyKey = receiverProxyKey
        self.senderProxyKey = senderProxyKey
    }

    init(_ data: DataSnapshot) throws {
        let dictionary = data.value as AnyObject
        guard let senderId = dictionary["senderId"] as? String,
            let senderDisplayName = dictionary["senderDisplayName"] as? String,
            let messageId = dictionary["messageId"] as? String,
            let sentDate = dictionary["sentDate"] as? Double,
            let text = dictionary["text"] as? String,
            let dateRead = dictionary["dateRead"] as? Double,
            let parentConvoKey = dictionary["parentConvoKey"] as? String,
            let receiverId = dictionary["receiverId"] as? String,
            let receiverProxyKey = dictionary["receiverProxyKey"] as? String,
            let senderProxyKey = dictionary["senderProxyKey"] as? String else {
                throw ProxyError.unknown
        }
        self.sender = Sender(id: senderId, displayName: senderDisplayName)
        self.messageId = messageId
        self.sentDate = Date(timeIntervalSince1970: sentDate)
        self.data = .text(text)
        self.dateRead = Date(timeIntervalSince1970: dateRead)
        self.parentConvoKey = parentConvoKey
        self.receiverId = receiverId
        self.receiverProxyKey = receiverProxyKey
        self.senderProxyKey = senderProxyKey
    }
}

extension Message: Equatable {
    static func == (_ lhs: Message, _ rhs: Message) -> Bool {
        return lhs.sender == rhs.sender &&
            lhs.messageId == rhs.messageId &&
            lhs.sentDate.timeIntervalSince1970.isWithinRangeOf(rhs.sentDate.timeIntervalSince1970) &&
            lhs.data == rhs.data &&
            lhs.dateRead.timeIntervalSince1970.isWithinRangeOf(rhs.dateRead.timeIntervalSince1970) &&
            lhs.parentConvoKey == rhs.parentConvoKey &&
            lhs.receiverId == rhs.receiverId &&
            lhs.receiverProxyKey == rhs.receiverProxyKey &&
            lhs.senderProxyKey == rhs.senderProxyKey
    }
}

extension Message: Hashable {
    var hashValue: Int {
        return Int(messageId) ?? UUID().hashValue
    }
}

extension MessageData: Equatable {
    public static func == (_ lhs: MessageData, _ rhs: MessageData) -> Bool {
        switch (lhs, rhs) {
        case (let .text(l), let .text(r)):
            return l == r
        default:
            return false
        }
    }
}
