import Firebase

class Shared {
    static let shared = Shared()

    // extract to separate package
    var asyncWorkGroups = [AsyncWorkGroupKey: (group: DispatchGroup, result: Bool)]()

    private init() {}
}
