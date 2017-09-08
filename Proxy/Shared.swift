import Firebase

class Shared {
    static let shared = Shared()

    let cache = NSCache<AnyObject, AnyObject>()
    let firebase = FirebaseApp.app()
    let queue = DispatchQueue(label: "proxyQueue")

    var asyncWorkGroups = [AsyncWorkGroupKey: (group: DispatchGroup, result: Bool)]()
    var isCreatingProxy = false
    var proxyNameWords = (adjectives: [String](), nouns: [String]())
    var proxyIconNames = [String]()
    var uid = ""

    private init() {
        loadProxyIconNames()
        loadProxyNameAdjectives()
        loadProxyNameNouns()
    }
}
