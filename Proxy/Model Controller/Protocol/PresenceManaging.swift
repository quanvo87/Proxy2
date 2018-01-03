protocol PresenceManaging: class {
    var presentInConvo: String { get set }
}

class PresenceManager: PresenceManaging {
    var presentInConvo = ""
}
