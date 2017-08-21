import Firebase

class Shared {
    static let shared = Shared()

    lazy var firebase = FirebaseApp.app()

    lazy var cache = NSCache<AnyObject, AnyObject>()

    lazy var adjectives = [String]()
    lazy var nouns = [String]()
    lazy var iconNames = [String]()

    lazy var asyncWorkGroups = [AsyncWorkGroupKey: (group: DispatchGroup, result: Bool)]()

    lazy var uid = ""
    lazy var isCreatingProxy = false

    private init() {}
}
