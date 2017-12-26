import FirebaseDatabase

class PresenceManager {
    private var ref: DatabaseReference?

    func load(_ uid: String) {
        ref = DB.makeReference(Child.userInfo, uid, Child.isPresent)
        ref?.onDisconnectRemoveValue()
    }
}
