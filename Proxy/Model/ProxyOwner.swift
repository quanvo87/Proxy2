import FirebaseDatabase

struct ProxyOwner: Equatable {
    let key: String
    let ownerId: String
    
    init(key: String, ownerId: String) {
        self.key = key
        self.ownerId = ownerId
    }

    init?(data: DataSnapshot, ref: DatabaseReference?) {
        let dictionary = data.value as AnyObject
        guard
            let key = dictionary["key"] as? String,
            let ownerId = dictionary["ownerId"] as? String else {
                ref?.child(data.key).removeValue()
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
        return lhs.key == rhs.key &&
            lhs.ownerId == rhs.ownerId
    }
}
