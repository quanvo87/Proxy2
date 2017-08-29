import Firebase

class Shared {
    static let shared = Shared()

    var firebase = FirebaseApp.app()

    var cache = NSCache<AnyObject, AnyObject>()

    var adjectives = [String]()
    var nouns = [String]()
    var iconNames = [String]()
    var proxyInfoIsLoaded: Bool {
        return !adjectives.isEmpty && !nouns.isEmpty && !iconNames.isEmpty
    }

    var asyncWorkGroups = [AsyncWorkGroupKey: (group: DispatchGroup, result: Bool)]()

    var uid = ""
    var isCreatingProxy = false

    private init() {}
}
