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

typealias AsyncWorkGroupKey = String

extension AsyncWorkGroupKey {
    var workResult: Success {
        return Shared.shared.asyncWorkGroups[self]?.result ?? false
    }

    init() {
        let workKey = UUID().uuidString
        Shared.shared.asyncWorkGroups[workKey] = (DispatchGroup(), true)
        self = workKey
    }

    static func makeAsyncWorkGroupKey() -> AsyncWorkGroupKey {
        return AsyncWorkGroupKey()
    }

    func finishWork(withResult result: Success) {
        setWorkResult(result)
        Shared.shared.asyncWorkGroups[self]?.group.leave()
    }

    func finishWorkGroup() {
        Shared.shared.asyncWorkGroups.removeValue(forKey: self)
    }

    func notify(completion: @escaping () -> Void) {
        Shared.shared.asyncWorkGroups[self]?.group.notify(queue: .main) {
            completion()
        }
    }

    @discardableResult
    func setWorkResult(_ result: Success) -> Success {
        let result = Shared.shared.asyncWorkGroups[self]?.result ?? false && result
        Shared.shared.asyncWorkGroups[self]?.result = result
        return result
    }

    func startWork() {
        Shared.shared.asyncWorkGroups[self]?.group.enter()
    }
}
