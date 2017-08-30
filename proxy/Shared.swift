import Firebase

class Shared {
    static let shared = Shared()

    var asyncWorkGroups = [AsyncWorkGroupKey: (group: DispatchGroup, result: Bool)]()
    let cache = NSCache<AnyObject, AnyObject>()
    let firebase = FirebaseApp.app()

    var uid = ""
    var isCreatingProxy = false

    var proxyNameWords = (adjectives: [String](), nouns: [String]())
    var proxyIconNames = [String]()

    private init() {
        loadProxyIconNames()
        loadProxyNameAdjectives()
        loadProxyNameNouns()
    }
}
