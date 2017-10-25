import Firebase

class Shared {
    static let shared = Shared()

    let cache = NSCache<AnyObject, AnyObject>()
    let firebase = FirebaseApp.app()
    let queue = DispatchQueue(label: "proxyQueue")

    var asyncWorkGroups = [AsyncWorkGroupKey: (group: DispatchGroup, result: Bool)]()

    private init() {}
}
