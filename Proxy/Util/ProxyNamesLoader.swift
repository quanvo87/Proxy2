import FirebaseDatabase

// https://www.swiftbysundell.com/posts/a-deep-dive-into-grand-central-dispatch-in-swift
class ProxyNamesLoader {
    private let ref = DB.makeReference(Child.proxyNames)
    private var pendingWorkItem: DispatchWorkItem?

    // todo: combine proxy name and owner -> miniProxy?
    // todo: make this take in uid of query maker
    // todo: filter out miniProxys belonging to query maker
    func load(_ query: String,
              querySize: UInt = Setting.querySizeForProxyNames,
              completion: @escaping ([String]) -> Void) {
        pendingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.ref?
                .queryOrderedByKey()
                .queryStarting(atValue: query)
                .queryLimited(toFirst: querySize)
                .observeSingleEvent(of: .value) { (data) in
                    var proxyKeys = [String]()
                    for child in data.children {
                        guard
                            let value = ((child as? DataSnapshot)?.value),
                            let name = (value as AnyObject)[Child.name] as? String else {
                                continue
                        }
                        proxyKeys.append(name)
                    }
                    completion(proxyKeys)
            }
        }
        pendingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250),
                                      execute: workItem)
    }
}
