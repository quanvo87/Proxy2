import FirebaseDatabase

// https://www.swiftbysundell.com/posts/a-deep-dive-into-grand-central-dispatch-in-swift
class ProxyNamesLoader {
    private let ref = DB.makeReference(Child.proxyKeys)
    private var pendingWorkItem: DispatchWorkItem?

    func load(_ query: String, querySize: UInt = Setting.querySizeForProxyNames, completion: @escaping ([String]) -> Void) {
        pendingWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.ref?
                .queryOrderedByKey()
                .queryStarting(atValue: query)
                .queryLimited(toFirst: querySize)
                .observeSingleEvent(of: .value) { (data) in
                    var proxyKeys = [String]()
                    for child in data.children {
                        guard let proxyKey = (child as? DataSnapshot)?.key else {
                            continue
                        }
                        proxyKeys.append(proxyKey)
                    }
                    completion(proxyKeys)
            }
        }
        pendingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250),
                                      execute: workItem)
    }
}
