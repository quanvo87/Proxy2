import FirebaseDatabase

struct BlockedUser {
    let blockee: String
    let blockeeProxyName: String
    let blocker: String
    let convoKey: String
    let dateBlocked: Double

    var asDictionary: Any {
        return [
            "blockee": blockee,
            "blockeeProxyName": blockeeProxyName,
            "blocker": blocker,
            "convoKey": convoKey,
            "dateBlocked": dateBlocked
        ]
    }

    init(convo: Convo, dateBlocked: Double = Date().timeIntervalSince1970) {
        self.blockee = convo.receiverId
        self.blockeeProxyName = convo.receiverProxyName
        self.blocker = convo.senderId
        self.convoKey = convo.key
        self.dateBlocked = dateBlocked
    }

    init(blockee: String,
         blockeeProxyName: String,
         blocker: String,
         convoKey: String,
         dateBlocked: Double = Date().timeIntervalSince1970) {
        self.blockee = blockee
        self.blockeeProxyName = blockeeProxyName
        self.blocker = blocker
        self.convoKey = convoKey
        self.dateBlocked = dateBlocked
    }

    init(_ data: DataSnapshot) throws {
        let dictionary = data.value as AnyObject
        guard let blockee = dictionary["blockee"] as? String,
            let blockeeProxyName = dictionary["blockeeProxyName"] as? String,
            let blocker = dictionary["blocker"] as? String,
            let convoKey = dictionary["convoKey"] as? String,
            let dateBlocked = dictionary["dateBlocked"] as? Double else {
                throw ProxyError.unknown
        }
        self.blockee = blockee
        self.blockeeProxyName = blockeeProxyName
        self.blocker = blocker
        self.convoKey = convoKey
        self.dateBlocked = dateBlocked
    }
}

extension BlockedUser: Equatable {
    static func == (_ lhs: BlockedUser, _ rhs: BlockedUser) -> Bool {
        return lhs.blockee == rhs.blockee &&
            lhs.blockeeProxyName == rhs.blockeeProxyName &&
            lhs.blocker == rhs.blocker &&
            lhs.convoKey == rhs.convoKey &&
            lhs.dateBlocked.isWithinRangeOf(rhs.dateBlocked)
    }
}
