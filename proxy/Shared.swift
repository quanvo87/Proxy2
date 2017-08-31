import Firebase

class Shared {
    static let shared = Shared()

    var asyncWorkGroups = [AsyncWorkGroupKey: (group: DispatchGroup, result: Bool)]()
    let cache = NSCache<AnyObject, AnyObject>()
    let firebase = FirebaseApp.app()
    let queue = DispatchQueue(label: "proxyQueue")

    var proxyNameWords = (adjectives: [String](), nouns: [String]())
    var proxyIconNames = [String]()

    var uid = ""
    var isCreatingProxy = false

    private init() {
        loadProxyIconNames()
        loadProxyNameAdjectives()
        loadProxyNameNouns()
    }
}
