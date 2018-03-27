import FirebaseDatabase

struct BlockedUser {
    let dateBlocked: Double
    let proxyName: String
    let uid: String

    var asDictionary: Any {
        return [
            "dateBlocked": dateBlocked,
            "proxyName": proxyName,
            "uid": uid
        ]
    }

    init(dateBlocked: Double = Date().timeIntervalSince1970,
         proxyName: String,
         uid: String) {
        self.dateBlocked = dateBlocked
        self.proxyName = proxyName
        self.uid = uid
    }

    init(_ data: DataSnapshot) throws {
        let dictionary = data.value as AnyObject
        guard let dateBlocked = dictionary["dateBlocked"] as? Double,
            let proxyName = dictionary["proxyName"] as? String,
            let uid = dictionary["uid"] as? String else {
                throw ProxyError.unknown
        }
        self.dateBlocked = dateBlocked
        self.proxyName = proxyName
        self.uid = uid
    }
}

extension BlockedUser: Equatable {
    static func == (_ lhs: BlockedUser, _ rhs: BlockedUser) -> Bool {
        return lhs.dateBlocked.isWithinRangeOf(rhs.dateBlocked) &&
            lhs.proxyName == rhs.proxyName &&
            lhs.uid == rhs.uid
    }
}
